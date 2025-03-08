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
    local response, err = ws:receive()
    if err then
        error("receive failure" .. err)
    elseif not response then
        return nil
    end
    return json.decode(response)
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

    while true do
        -- TODO add delay between receive? or is the timeout sufficient to be non-blocking?
        local response, err = ws:receive(1000)
        if err then
            print("listenToOutputEvents Failure:", err)
            return
        end
        if response then
            local decoded = json.decode(response)
            printJson("listenToOutputEvents response:", decoded)
        end
    end
end

function _M.getSceneList()
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
