-- FYI http.websocket:
--   docks: https://daurnimator.github.io/lua-http/0.4/
--   https://github.com/daurnimator/lua-http/blob/master/http/websocket.lua
local http_websocket = require("http.websocket")
local json = require("dkjson")
require("config.macros.streamdeck.obs.constants")
require("config.macros.streamdeck.obs.helpers")

local connectAndAuthenticate = require("config.macros.streamdeck.obs.connect").connectAndAuthenticate

local _M = {}

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

local function expectOpCode(message, expectedOpCode)
    if message.op == expectedOpCode then
        return
    end

    local opcodeText = getFirstKeyForValue(WebSocketOpCode, message.op) or ""
    error("expected op to be " .. expectedOpCode .. " (RequestResponse), got " .. message.op .. " (" .. opcodeText .. ")")
end

local function expectRequestResponse(request, response)
    if not response then
        error("no response received")
    end

    expectOpCode(response, WebSocketOpCode.RequestResponse)

    if request.d.requestId ~= response.d.requestId then
        error("requestId mismatch, expected " .. request.d.requestId .. ", got " .. response.d.requestId)
    end

    -- could check response.d.requestType == request.d.requestType but checking requestId s/b sufficient
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

        error("requestStatus is not ok, comment: " .. response.d.requestStatus.comment
            .. ", code: " .. response.d.requestStatus.code .. " (" .. codeText .. ")")
    end
end

function getOutputStatus()
    local ws = connectAndAuthenticate()

    local request = createRequest(Requests.Outputs.GetOutputStatus)
    ws_send(ws, request)

    local response = receiveDecoded(ws)
    expectRequestResponse(request, response)
    expectRequestStatusIsOk(response)
    if response then
        printJson("Received Output Status:", response)
    else
        print("No response received")
    end

    ws:close()
end

function getSceneList()
    local ws = connectAndAuthenticate()

    -- BTW list of requests: https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#requests
    local request = {
        op = WebSocketOpCode.Request,
        d = {
            -- https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#getscenelist
            requestType = "GetSceneList",
            requestId = uuid(),
        }
    }

    ws:send(json.encode(request))

    local response = receiveDecoded(ws)
    if response then
        printJson("Received Scene List:", response)
    else
        print("No response received")
    end

    ws:close()
end

return _M
