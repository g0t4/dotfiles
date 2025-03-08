-- FYI http.websocket:
--   docks: https://daurnimator.github.io/lua-http/0.4/
--   https://github.com/daurnimator/lua-http/blob/master/http/websocket.lua
local http_websocket = require("http.websocket")
local json = require("dkjson")
require("config.macros.streamdeck.obs.constants")
require("config.macros.streamdeck.obs.helpers")

local connectAndAuthenticate = require("config.macros.streamdeck.obs.connect").connectAndAuthenticate

local M = {}

-- ***! check OBS logs:  '/Users/wesdemos/Library/Application Support/obs-studio/logs/'
--    it will tell you what isn't working

function listenToOutputEvents()
    local ws = connectAndAuthenticate()

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
            print("timeout, ignoring...")
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
        local codeText = getFirstKeyForValue(RequestStatusUnvalidated, response.d.requestStatus.code) or ""

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

function getSceneList()
    getAndPrint(Requests.Scenes.GetSceneList)
end

function getProfileList()
    getAndPrint(Requests.Config.GetProfileList)
end

function getVideoSettings()
    getAndPrint(Requests.Config.GetVideoSettings)
end

function getRecordDirectory()
    getAndPrint(Requests.Config.GetRecordDirectory)
end

function setRecordDirectory(directory)
    getAndPrint(Requests.Config.SetRecordDirectory, {
        recordDirectory = directory,
    })
end

function getCurrentProgramScene()
    getAndPrint(Requests.Scenes.GetCurrentProgramScene)
end

function getCurrentPreviewScene()
    getAndPrint(Requests.Scenes.GetCurrentPreviewScene)
end

function getVersion()
    getAndPrint(Requests.General.GetVersion)
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
        return getResponseData(Requests.Outputs.GetVirtualCamStatus).outputActive
    end,
    toggle = function()
        getAndPrint(Requests.Outputs.ToggleVirtualCam)
        -- TODO verify toggled
    end,
    start = function()
        getAndPrint(Requests.Outputs.StartVirtualCam)
        -- TODO verify started
    end,
    stop = function()
        getAndPrint(Requests.Outputs.StopVirtualCam)
        -- TODO verify stopped
    end,
}

Streaming = {
    ---@return boolean
    status = function()
        return getResponseData(Requests.Stream.GetStreamStatus)
    end,
    ---@return boolean # active or inactive after toggle
    toggle = function()
        return getResponseData(Requests.Stream.ToggleStream).outputActive
    end,
    start = function()
        getAndPrint(Requests.Stream.StartStream)
    end,
    stop = function()
        getAndPrint(Requests.Stream.StopStream)
    end,
    sendCaption = function(text)
        getAndPrint(Requests.Stream.SendStreamCaption, {
            caption = text,
        })
    end,
}

--- Prefer over Outputs.Recording
Record = {
    --- FYI YUP second set of controls for recording... I should probably prefer this over Outputs.Recording
    ---@return boolean
    status = function()
        return getResponseData(Requests.Record.GetRecordStatus)
    end,
    toggle = function()
        getAndPrint(Requests.Record.ToggleRecord)
    end,
    start = function()
        getAndPrint(Requests.Record.StartRecord)
    end,
    stop = function()
        getAndPrint(Requests.Record.StopRecord)
    end,
    pause = function()
        getAndPrint(Requests.Record.PauseRecord)
    end,
    resume = function()
        getAndPrint(Requests.Record.ResumeRecord)
    end,
    togglePause = function()
        getAndPrint(Requests.Record.ToggleRecordPause)
    end,
    splitRecordFile = function()
        getAndPrint(Requests.Record.SplitRecordFile)
    end,
    createRecordChapter = function()
        getAndPrint(Requests.Record.CreateRecordChapter)
    end,
}

return M
