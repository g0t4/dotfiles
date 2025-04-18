local http_websocket = require("http.websocket")
local json = require("dkjson")

local M = {}

function connectToOBS()
    local ws, error1 = http_websocket.new_from_uri("ws://localhost:4455")
    if not ws then
        error("Failed to connect:" .. hs.inspect(error1))
    end

    local success, errorConnect = ws:connect()
    if success then
        return ws
    end
    if errorConnect and errorConnect:match("Connection refused") then
        hs.alert.show("OBS is not running or its websocket is not listening")
    end
    error("WebSocket connection error:" .. hs.inspect(errorConnect))
end

local function authenticate(ws, eventFlags)
    eventFlags = eventFlags or 0
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
                eventSubscriptions = eventFlags
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
            eventSubscriptions = eventFlags
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


-- TODO ADD TYPING of ws return type
--    CARRY OVER TO other uses like receiveDecoded
--- @param eventFlags number|nil
function M.connectAndAuthenticate(eventFlags)
    local ws = connectToOBS()
    authenticate(ws, eventFlags)
    return ws
end

return M
