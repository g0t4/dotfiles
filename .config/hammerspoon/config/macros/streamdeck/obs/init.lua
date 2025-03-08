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
        if errorCode == 60 then
            print("timeout, ignoring...")
            return nil
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
        end
        print("nothing received yet")
        -- TODO adjust delay between checks, avoids blocking hammerspoon process (ws_receive is blocking)
        hs.timer.doAfter(1, checkForOutputs)
    end
    hs.timer.doAfter(0.1, checkForOutputs)
end

function getSceneList()
    local ws = connectAndAuthenticate()

    -- BTW list of requests: https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#requests
    local request = {
        op = WebSocketOpCode.Request,
        d = {
            -- https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#getscenelist
            requestType = "GetSceneList",
            requestId = uuid()
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
