local http_websocket = require("http.websocket")
local json = require("dkjson")

-- WebSocketOpCode::Hello
-- The initial message sent by obs-websocket to newly connected clients.
--
-- Identifier Value: 0
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::Identify
-- The message sent by a newly connected client to obs-websocket in response to a Hello.
--
-- Identifier Value: 1
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::Identified
-- The response sent by obs-websocket to a client after it has successfully identified with obs-websocket.
--
-- Identifier Value: 2
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::Reidentify
-- The message sent by an already-identified client to update identification parameters.
--
-- Identifier Value: 3
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::Event
-- The message sent by obs-websocket containing an event payload.
--
-- Identifier Value: 5
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::Request
-- The message sent by a client to obs-websocket to perform a request.
--
-- Identifier Value: 6
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::RequestResponse
-- The message sent by obs-websocket in response to a particular request from a client.
--
-- Identifier Value: 7
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::RequestBatch
-- The message sent by a client to obs-websocket to perform a batch of requests.
--
-- Identifier Value: 8
-- Latest Supported RPC Version: 1
-- Added in v5.0.0
-- WebSocketOpCode::RequestBatchResponse
-- The message sent by obs-websocket in response to a particular batch of requests from a client.
--
-- Identifier Value: 9
-- Latest Supported RPC Version: 1
-- Added in v5.0.0

local WebSocketOpCode = {
    Hello = 0,
    Identify = 1,
    Identified = 2,
    Reidentify = 3,
    Event = 5,
    Request = 6,
    RequestResponse = 7,
    RequestBatch = 8,
    RequestBatchResponse = 9,
}

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
    local ws, error = http_websocket.new_from_uri("ws://localhost:4455")
    if not ws then
        error("Failed to connect:" .. hs.inspect(error))
    end

    local success, errorConnect = ws:connect()
    if success then
        return ws
    end
    error("WebSocket connection error:" .. hs.inspect(errorConnect))
end

local function receive(ws)
    local response = ws:receive()
    if not response then
        error("No response received")
    end
    return json.decode(response)
end

local function authenticate(ws)
    local response = receive(ws)
    if response.op ~= 0 then
        error_unexpected_response(response)
    end
    print_json("Received Hello", response)

    if not response.d.authentication then
        -- FYI can send opcode 1 => https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#identify-opcode-1
        --     with PubSub subscriptions, and session parameters
        print("success, no authentication")
        ws:send(json.encode({
            op = 1,
            d = {
                rpcVersion = 1,
                eventSubscriptions = 0
            }
        }))
        response = receive(ws)
        if response.op ~= 2 then
            error_unexpected_response(response)
        end
        print_json("Received Identify Response", response)
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
    authenticate(ws)
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
