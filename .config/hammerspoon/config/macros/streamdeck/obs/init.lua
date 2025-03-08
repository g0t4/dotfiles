-- FYI http.websocket:
--   docks: https://daurnimator.github.io/lua-http/0.4/
--   https://github.com/daurnimator/lua-http/blob/master/http/websocket.lua
local json = require("dkjson")
require("config.macros.streamdeck.obs.constants")
require("config.macros.streamdeck.obs.helpers")

local connectAndAuthenticate = require("config.macros.streamdeck.obs.connect").connectAndAuthenticate

local M = {}

-- ***! check OBS logs:  '/Users/wesdemos/Library/Application Support/obs-studio/logs/'
--    it will tell you what isn't working

-- TODO Events to handle
--  CurrentProgramSceneChanged
--  CurrentPreviewSceneChanged
--  StreamStateChanged
--  RecordStateChanged
--
-- low priority:
--   ExitStarted  -- shut down listeners... though they will stop naturally :)
--   RecordFileChanged (button could show name?)

function listenForRelevantEvents()
    local eventFlags = EventSubscriptionBitFlags.Outputs | EventSubscriptionBitFlags.Scenes
    local ws = connectAndAuthenticate(eventFlags)

    local function checkForOutputs()
        local textFrame, binaryFrame, err, errorCode = ws_receive(ws, 1)
        if errorCode == 1001 then
            -- FYI I quit OBS while polling and got 1001 error code
            --  use this to terminate listening, gracefully
            --  also later add app listener if this should resume on next OBS start
            --    this needs to be moved into logic for buttons that depend on output events from OBS
            --      stop in the button would stop monitoring
            --      probably don't want all buttons to have separate listeners... so need a shared way to track listeners and stop when none are left
            --      and also can add App Listener to start/stop websocket polling
            print("obs quit, stopping listening")
            ws:close()
            return
        end
        if errorCode == 60 then
            -- print("timeout, ignoring...")
            hs.timer.doAfter(1, checkForOutputs)
            return
        end
        if err then
            local message = "error receiving frame: " .. err
            if errorCode then
                message = message .. ", errorCode: " .. errorCode
            end
            error(message)
        end
        if binaryFrame then
            error("unexpected binary frame, was expecting a text frame")
        end
        if textFrame then
            local decoded = json.decode(textFrame)
            printJson("listenToOutputEvents response:", decoded)
            -- PRN? if just got a message, immediately check for more?
        end
        -- print("nothing received yet")
        hs.timer.doAfter(0.5, checkForOutputs)
    end
    hs.timer.doAfter(0.1, checkForOutputs)
end

function expectRequestStatusIsOk(response)
    -- i.e. here is what happens when missing request parameters in requestData
    -- {
    --   "op":7,
    --   "d":{
    --     "requestStatus":{
    --       "comment":"Your request data is missing or invalid (non-object)",
    --       "result":false,
    --       "code":301
    --     },
    --     "requestType":"GetOutputStatus",
    --     "requestId":"483879bc-3640-4acf-ac9f-0833de629227"
    --   }
    -- }
    if not response.d.requestStatus then
        error("no requestStatus in response")
    end
    if response.d.requestStatus.result ~= true then
        local codeText = getFirstKeyForValue(RequestStatus, response.d.requestStatus.code) or ""

        local commentText = response.d.requestStatus.comment or ""

        error("requestStatus is not ok, comment: " .. commentText
            .. ", code: " .. response.d.requestStatus.code .. " (" .. codeText .. ")")
    end
end

-- --- FYI use Recording and Streaming controls instead of Outputs.Recording/Streaming unless they don't do something you need
-- ---@class Output
-- ---@field outputName string
-- local Output = {}
--
-- function Output.list()
--     return getResponseData(Requests.Outputs.GetOutputList).outputs
-- end
--
-- function Output.new(outputName)
--     local self = setmetatable({}, { __index = Output })
--     self.outputName = outputName
--     return self
-- end
--
-- Outputs = {
--     Recording = Output.new("simple_file_output"),
--     Streaming = Output.new("virtualcam_output")
-- }
--
-- function Output:status()
--     return getResponseData(Requests.Outputs.GetOutputStatus, {
--         outputName = self.outputName,
--     })
-- end
--
-- function Output:isActive()
--     return self:status().outputActive
-- end
--
-- ---@return boolean # active or inactive after toggle
-- function Output:toggle()
--     return getResponseData(Requests.Outputs.ToggleOutput, {
--         outputName = self.outputName,
--     }).outputActive
-- end
--
-- function Output:start()
--     return getResponseData(Requests.Outputs.StartOutput, {
--         outputName = self.outputName,
--     })
-- end
--
-- function Output:stop()
--     return getResponseData(Requests.Outputs.StopOutput, {
--         outputName = self.outputName,
--     })
-- end
--
-- function Output:settings()
--     -- FYI appears to show last recording file
--     -- outputSettings = {
--     --   muxer_settings = "",
--     --   path = "/Users/wes.../2025-03-08 13-27.mkv"
--     -- }
--
--     return getResponseData(Requests.Outputs.GetOutputSettings, {
--         outputName = self.outputName,
--     })
-- end

MyScenes = {
    ScreenWithCornerCamera = "d1a6b43d-7878-4f0c-ac2d-75f50c95ff05",
    ScreenOnly = "ffe52e1d-6831-4fb5-8afe-060c372c5791",
    CameraOnly = "16b3b395-d25f-466f-ae8d-df28c5321eab",
    ScreenWithHugeCamera = "a6a5bb4a-568a-49f4-ac56-36cb7266c8b6",
}
Scenes = {
    setScreenCornerCamera = function()
        Scenes.setCurrentProgramScene(MyScenes.ScreenWithCornerCamera)
    end,
    setScreenOnly = function()
        Scenes.setCurrentProgramScene(MyScenes.ScreenOnly)
    end,
    setCameraOnly = function()
        Scenes.setCurrentProgramScene(MyScenes.CameraOnly)
    end,
    setScreenWithHugeCamera = function()
        Scenes.setCurrentProgramScene(MyScenes.ScreenWithHugeCamera)
    end,
}
function Scenes.list()
    return execAndReturnData(Requests.Scenes.GetSceneList)
end

---FYI it appears the name/uuid are redundant in output
---@return table { sceneName: string, sceneUuid: string, currentProgramSceneName: string, currentProgramSceneUuid: string }
function Scenes.currentProgramScene()
    return execAndReturnData(Requests.Scenes.GetCurrentProgramScene)
end

---FYI it appears the name/uuid are redundant in output
---@return table { sceneName: string, sceneUuid: string, currentPreviewSceneName: string, currentPreviewSceneUuid: string }
function Scenes.currentPreviewScene()
    -- TODO check if studio mode is enabled? otherwise cannot use this
    return execAndReturnData(Requests.Scenes.GetCurrentPreviewScene)
end

---@param sceneUuid string
function Scenes.setCurrentProgramScene(sceneUuid)
    execAndPrintResponse(Requests.Scenes.SetCurrentProgramScene, {
        sceneUuid = sceneUuid,
    })
end

---@param sceneUuid string
function Scenes.setCurrentPreviewScene(sceneUuid)
    execAndPrintResponse(Requests.Scenes.SetCurrentPreviewScene, {
        sceneUuid = sceneUuid,
    })
end

Profiles = {}
function Profiles.list()
    return execAndReturnData(Requests.Config.GetProfileList)
end

Config = {}
function Config.videoSettings()
    return execAndReturnData(Requests.Config.GetVideoSettings)
end

function Config.recordDirectory()
    return execAndReturnData(Requests.Config.GetRecordDirectory)
end

function Config.setRecordDirectory(directory)
    -- todo turn into set and verify?
    execAndPrintResponse(Requests.Config.SetRecordDirectory, {
        recordDirectory = directory,
    })
end

General = {}
function General.getVersion()
    return execAndReturnData(Requests.General.GetVersion)
end

-- function getSourceScreenshot(sourceName)
--     getAndPrint(Requests.Sources.GetSourceScreenshot, {
--         -- IIAC one or the other:
--         sourceName = sourceName,
--         sourceUuid = sourceUuid,
--         imageFormat = ?  -- use GetVersion to get list of formats
--         imageHeight/imageWidth
--     })
-- end

-- Inputs/Outputs/Transitions/Filters/SceneItems/

VirtualCam = {
    ---@return boolean
    status = function()
        return execAndReturnData(Requests.Outputs.GetVirtualCamStatus).outputActive
    end,
    toggle = function()
        execAndPrintResponse(Requests.Outputs.ToggleVirtualCam)
        -- TODO verify toggled
    end,
    start = function()
        execAndPrintResponse(Requests.Outputs.StartVirtualCam)
        -- TODO verify started
    end,
    stop = function()
        execAndPrintResponse(Requests.Outputs.StopVirtualCam)
        -- TODO verify stopped
    end,
}

Streaming = {
    ---@return boolean
    status = function()
        return execAndReturnData(Requests.Stream.GetStreamStatus)
    end,
    ---@return boolean # active or inactive after toggle
    toggle = function()
        return execAndReturnData(Requests.Stream.ToggleStream).outputActive
    end,
    start = function()
        execAndPrintResponse(Requests.Stream.StartStream)
    end,
    stop = function()
        execAndPrintResponse(Requests.Stream.StopStream)
    end,
    sendCaption = function(text)
        execAndPrintResponse(Requests.Stream.SendStreamCaption, {
            caption = text,
        })
    end,
}

--- Prefer over Outputs.Recording
Record = {
    --- FYI YUP second set of controls for recording... I should probably prefer this over Outputs.Recording
    ---@return table { outputActive: boolean, outputBytes: number, outputDuration: number, outputPaused: boolean, outputTimecode: string }
    status = function()
        return execAndReturnData(Requests.Record.GetRecordStatus)
    end,
    ---@return boolean # active or inactive after toggle
    toggle = function()
        return execAndReturnData(Requests.Record.ToggleRecord).outputActive
    end,
    start = function()
        execAndPrintResponse(Requests.Record.StartRecord)
    end,
    stop = function()
        execAndPrintResponse(Requests.Record.StopRecord)
    end,
    pause = function()
        execAndPrintResponse(Requests.Record.PauseRecord)
    end,
    resume = function()
        execAndPrintResponse(Requests.Record.ResumeRecord)
    end,
    togglePause = function()
        execAndPrintResponse(Requests.Record.ToggleRecordPause)
    end,
    splitRecordFile = function()
        execAndPrintResponse(Requests.Record.SplitRecordFile)
    end,
    createRecordChapter = function()
        execAndPrintResponse(Requests.Record.CreateRecordChapter)
    end,
}

return M
