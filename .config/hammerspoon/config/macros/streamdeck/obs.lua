local http_websocket = require("http.websocket")
local json = require("dkjson")

-- The initial message sent by obs-websocket to newly connected clients.
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

local WebSocketCloseCode = {
    DontClose = 0,
    UnknownReason = 4000,
    MessageDecodeError = 4002,
    MissingDataField = 4003,
    InvalidDataFieldType = 4004,
    InvalidDataFieldValue = 4005,
    UnknownOpCode = 4006,
    NotIdentified = 4007,
    AlreadyIdentified = 4008,
    AuthenticationFailed = 4009,
    UnsupportedRpcVersion = 4010,
    SessionInvalidated = 4011,
    UnsupportedFeature = 4012,
}

local RequestBatchExecutionType = {
    None = -1,
    SerialRealtime = 0,
    SerialFrame = 1,
    Parallel = 2,
}

local RequestStatus = {
    Unknown = 0,
    NoError = 10,
    Success = 100,
    MissingRequestType = 203,
    UnknownRequestType = 204,
    GenericError = 205,
    UnsupportedRequestBatchExecutionType = 206,
    NotReady = 207,
    MissingRequestField = 300,
    MissingRequestData = 301,
    InvalidRequestField = 400,
    InvalidRequestFieldType = 401,
    RequestFieldOutOfRange = 402,
    RequestFieldEmpty = 403,
    TooManyRequestFields = 404,
    OutputRunning = 500,
    OutputNotRunning = 501,
    OutputPaused = 502,
    OutputNotPaused = 503,
    OutputDisabled = 504,
    StudioModeActive = 505,
    StudioModeNotActive = 506,
    ResourceNotFound = 600,
    ResourceAlreadyExists = 601,
    InvalidResourceType = 602,
    NotEnoughResources = 603,
    InvalidResourceState = 604,
    InvalidInputKind = 605,
    ResourceNotConfigurable = 606,
    InvalidFilterKind = 607,
    ResourceCreationFailed = 700,
    ResourceActionFailed = 701,
    RequestProcessingFailed = 702,
    CannotAct = 703
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
