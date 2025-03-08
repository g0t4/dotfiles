local http_websocket = require("http.websocket")
local json = require("dkjson")

local function print_json(message, table)
    print(message, json.encode(table, { indent = true }))
end
local function error_unexpected_response(response)
    error("Received unexpected response: " .. json.encode(response, { indent = true }))
end

local function encode64(input)
    local pipe = io.popen("echo -n " .. string.format("%q", input) .. " | base64", "r")
    local result = pipe:read("*a")
    pipe:close()
    return result:gsub("\n", "") -- Remove trailing newline
end

local function sha256(input)
    local pipe = io.popen("echo -n " .. string.format("%q", input) .. " | sha256sum", "r")
    local result = pipe:read("*a")
    pipe:close()
    return result:gsub("%s+", "") -- :sub(1, 64) -- Remove whitespace and truncate to 64 characters
end

local function connect_to_obs()
    local ws, err = http_websocket.new_from_uri("ws://localhost:4455")
    if not ws then
        print("Failed to connect:", err)
        return nil
    end

    local success, err = ws:connect()
    if not success then
        print("WebSocket connection error:", err)
        return nil
    end

    print("Connected to OBS WebSocket")
    return ws
end

local function receive(ws)
    local response = ws:receive()
    if not response then
        error("No response received")
    end
    return json.decode(response)
end

local function receive_hello(ws)
    local response = receive(ws)
    if response.op ~= 0 then
        error_unexpected_response(response)
    end
    print_json("Received Hello", response)

    if not response.d.authentication then
        -- FYI can send opcode 1 => https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#identify-opcode-1
        --     with PubSub subscriptions, and session parameters

        print("success, no authentication")
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
    -- response has auth challenge:
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


    local function get_auth_string(hello, password)
        -- Concatenate the websocket password with the salt provided by the server (password + salt)
        local salt = hello.d.authentication.salt
        local challenge = hello.d.authentication.challenge
        local password_plus_salt = password .. salt
        -- Generate an SHA256 binary hash of the result and base64 encode it, known as a base64 secret.
        local base64_secret = encode64(sha256(password_plus_salt))
        -- Concatenate the base64 secret with the challenge sent by the server (base64_secret + challenge)
        local base64_secret_plus_challenge = base64_secret .. challenge
        -- Generate a binary SHA256 hash of that result and base64 encode it. You now have your authentication string.
        local auth_string = encode64(sha256(base64_secret_plus_challenge))
        print("auth string:", auth_string)
    end

    local password = "foobar"
    local auth_string = get_auth_string(response, password)
    -- Identify request:
    -- {
    --   "op": 1,
    --   "d": {
    --     "rpcVersion": 1,
    --     "authentication": "Dj6cLS+jrNA0HpCArRg0Z/Fc+YHdt2FQfAvgD1mip6Y=",
    --     "eventSubscriptions": 33
    --   }
    -- }
    ws:send(json.encode({
        op = 1,
        d = {
            rpcVersion = 1,
            authentication = auth_string,
            eventSubscriptions = 0
        }
    }))
    -- EVENT SUBSCRIPTIONS:  https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#eventsubscription
    --    bitmask, default on for all subscriptions except high volume

    -- should get back opcode 2 after sending identify
    local response = ws:receive()
    if not response then
        error("No response received")
    end


    return true
end

local function get_scene_list()
    local ws = connect_to_obs()
    receive_hello(ws)
    if not ws then return end

    local request = {
        op = 6, -- OBS WebSocket Request type
        d = {
            requestType = "GetSceneList",
            requestId = "1234"
        }
    }

    ws:send(json.encode(request))

    local response = ws:receive()
    if response then
        local decoded_response = json.decode(response)
        print("Received Scene List:", json.encode(decoded_response, { indent = true }))
    else
        print("No response received")
    end

    ws:close()
end

get_scene_list()
