-- FYI http.websocket:
--   docks: https://daurnimator.github.io/lua-http/0.4/
--   https://github.com/daurnimator/lua-http/blob/master/http/websocket.lua
local http_websocket = require("http.websocket")
local json = require("dkjson")
require("config.macros.streamdeck.obs.constants")
local _M = {}

-- ***! check OBS logs:  '/Users/wesdemos/Library/Application Support/obs-studio/logs/'
--    it will tell you what isn't working
local function printJson(message, table)
    print(message, json.encode(table, { indent = true }))
end
local function errorUnexpectedResponse(response)
    if not response then
        error("Received no response")
    end
    error("Received unexpected response: " .. json.encode(response, { indent = true }))
end

---Wrapper around ws:receive to provide types and split second arg intelligently for consumers
---@param ws table
---@param timeout integer|nil # in SECONDS (see https://daurnimator.github.io/lua-http/0.4/#timeouts)
---@return string|nil textFrame, binary|nil binaryFrame, string|nil error, string|nil errorCode
local function ws_receive(ws, timeout)
    -- TODO does timeout default to infinite?
    -- TODO can I wrap in coroutine and not need to worry about timeout?
    --    https://daurnimator.github.io/lua-http/0.4/#asynchronous-operation
    --    mentions non-blocking in cqueue or compatible container (IIAC coroutine?)
    --    or does this not apply to ws:receive?
    -- TODO cqueues:  https://25thandclement.com/~william/projects/cqueues.html
    --   ok yup, uses yielding coroutines to communicate w/ event controller

    local frame, errorOrFrameType, errorCode = ws:receive(timeout)
    if errorCode then
        return nil, nil, errorOrFrameType, errorCode
    end
    -- errorOrFrame holds a type string
    if errorOrFrameType == "text" then
        return frame
    end
    -- PRN what is the type on a binary frame? find example of this and test it?
    return nil, frame
end

local function connectToOBS()
    local ws, error1 = http_websocket.new_from_uri("ws://localhost:4455")
    if not ws then
        error("Failed to connect:" .. hs.inspect(error1))
    end

    local success, errorConnect = ws:connect()
    if success then
        return ws
    end
    error("WebSocket connection error:" .. hs.inspect(errorConnect))
end

local function receiveDecoded(ws)
    -- PRN pass timeout? to receive?

    -- The opcode 0x1 will be returned as "text" and 0x2 will be returned as "binary".
    local textFrame, binaryFrame, err, errorCode = ws_receive(ws)
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
        return json.decode(textFrame)
    end
    return nil
end

local function authenticate(ws)
    local response = receiveDecoded(ws)
    if not response or response.op ~= WebSocketOpCode.Hello then
        errorUnexpectedResponse(response)
    end
    -- printJson("Received Hello", response)

    if not response.d.authentication then
        -- FYI can send opcode 1 => https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#identify-opcode-1
        --     with PubSub subscriptions, and session parameters
        print("success, no authentication")
        ws:send(json.encode({
            op = WebSocketOpCode.Identify,
            d = {
                rpcVersion = 1,
                eventSubscriptions = 0
            }
        }))
        response = receiveDecoded(ws)
        if not response or response.op ~= WebSocketOpCode.Identified then
            errorUnexpectedResponse(response)
        end
        -- printJson("Received Identify Response", response)
        -- response has no auth challenge:
        -- {
        --   "d":{
        --     "obsWebSocketVersion":"5.5.4",
        --     "rpcVersion":1
        --   },
        --   "op":0
        -- }
        -- TODO send identify w/o auth
        return true
    end
    print("auth challenge received")
    -- auth response example:
    -- {
    --   "d":{
    --     "obsWebSocketVersion":"5.5.4",
    --     "authentication":{
    --       "salt":"...=",
    --       "challenge":"...="
    --     },
    --     "rpcVersion":1
    --   },
    --   "op":0
    -- }

    function sha256ThenBase64(input)
        -- FYI io.popen DOES NOT PARSE LIKE A SHELL... if I pass "echo -n foobar" it results in "-n foobar" in the output?!?
        --   but it then does allow piping to other commands... WTF?
        --   printf would be another choice if issues with echo
        --   BE VERY CAREFUL ABOUT HOW YOU ALTER THIS CODE
        -- --quiet strips the trailing - (filename) which is STDOUT...
        --   strip \n added by echo since I cannot pass -n to echo here
        local cmd = "echo " .. string.format("%q", input) .. ' | tr -d "\n" | openssl dgst -sha256 -binary | base64 '
        local pipe = io.popen(cmd, "r")
        local result = pipe:read("*a")
        pipe:close()
        return result:gsub("\n$", "")
    end

    local function getAuthenticationString(hello, password)
        -- https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#creating-an-authentication-string

        -- Concatenate the websocket password with the salt provided by the server (password + salt)
        local salt = hello.d.authentication.salt
        local password_plus_salt = password .. salt
        -- print("  password_plus_salt:", password_plus_salt)

        -- Generate an SHA256 binary hash of the result and base64 encode it, known as a base64 secret.
        local base64_secret = sha256ThenBase64(password_plus_salt)
        -- print("  base64_secret:", base64_secret)

        -- Concatenate the base64 secret with the challenge sent by the server (base64_secret + challenge)
        local challenge = hello.d.authentication.challenge
        local base64_secret_plus_challenge = base64_secret .. challenge
        -- print("  base64_secret_plus_challenge:", base64_secret_plus_challenge)

        -- Generate a binary SHA256 hash of that result and base64 encode it. You now have your authentication string.
        local auth_string = sha256ThenBase64(base64_secret_plus_challenge)
        -- print("  auth string:", auth_string)

        return auth_string
    end

    local password = "foobar"
    local auth_string = getAuthenticationString(response, password)
    -- Identify request:
    -- {
    --   "op": 1,
    --   "d": {
    --     "rpcVersion": 1,
    --     "authentication": "Dj6cLS+jrNA0HpCArRg0Z/Fc+YHdt2FQfAvgD1mip6Y=",
    --     "eventSubscriptions": 33
    --   }
    -- }
    local identify = json.encode({
        op = WebSocketOpCode.Identify,
        d = {
            rpcVersion = 1,
            authentication = auth_string,
            eventSubscriptions = EventSubscriptionBitFlagsUnvalidated.Outputs
        }
    })
    -- print("identify:", identify)
    ws:send(identify)
    -- TODO EVENT SUBSCRIPTIONS:  https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#eventsubscription
    --    bitmask, default on for all subscriptions except high volume

    -- should get back opcode 2 after sending identify
    local identifyResponse = receiveDecoded(ws)
    -- print("response after identify:", json.encode(response, { indent = true }))
    if not identifyResponse or identifyResponse.op ~= WebSocketOpCode.Identified then
        errorUnexpectedResponse(identifyResponse)
    end
end

function listenToOutputEvents()
    local ws = connectToOBS()
    authenticate(ws)

    local function checkForOutputs()
        local textFrame, binaryFrame, err, errorCode = ws_receive(ws, 1)
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
    local ws = connectToOBS()
    authenticate(ws)

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
