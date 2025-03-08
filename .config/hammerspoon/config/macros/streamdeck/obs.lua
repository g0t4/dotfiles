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

local RequestStatusUnvalidated = {
    -- FYI these are from ChatGPT and Inception's model but I did not validate them myself yet
    Unknown = 0, -- Unknown status, should never be used.
    NoError = 10, -- For internal use to signify a successful field check.
    Success = 100, -- The request has succeeded.
    MissingRequestType = 203, -- The requestType field is missing from the request data.
    UnknownRequestType = 204, -- The request type is invalid or does not exist.
    GenericError = 205, -- Generic error code. Note: A comment is required to be provided by obs-websocket.
    UnsupportedRequestBatchExecutionType = 206, -- The request batch execution type is not supported.
    NotReady = 207, -- The server is not ready to handle the request. Note: This usually occurs during OBS scene collection change or exit. Requests may be tried again after a delay if this code is given.
    MissingRequestField = 300, -- A required request field is missing.
    MissingRequestData = 301, -- The request does not have a valid requestData object.
    InvalidRequestField = 400, -- Generic invalid request field message. Note: A comment is required to be provided by obs-websocket.
    InvalidRequestFieldType = 401, -- A request field has the wrong data type.
    RequestFieldOutOfRange = 402, -- A request field (number) is outside of the allowed range.
    RequestFieldEmpty = 403, -- A request field (string or array) is empty and cannot be.
    TooManyRequestFields = 404, -- There are too many request fields (eg. a request takes two optionals, where only one is allowed at a time).
    OutputRunning = 500, -- An output is running and cannot be in order to perform the request.
    OutputNotRunning = 501, -- An output is not running and should be.
    OutputPaused = 502, -- An output is paused and should not be.
    OutputNotPaused = 503, -- An output is not paused and should be.
    OutputDisabled = 504, -- An output is disabled and should not be.
    StudioModeActive = 505, -- Studio mode is active and cannot be.
    StudioModeNotActive = 506, -- Studio mode is not active and should be.
    ResourceNotFound = 600, -- The resource was not found. Note: Resources are any kind of object in obs-websocket, like inputs, profiles, outputs, etc.
    ResourceAlreadyExists = 601, -- The resource already exists.
    InvalidResourceType = 602, -- The type of resource found is invalid.
    NotEnoughResources = 603, -- There are not enough instances of the resource in order to perform the request.
    InvalidResourceState = 604, -- The state of the resource is invalid. For example, if the resource is blocked from being accessed.
    InvalidInputKind = 605, -- The specified input (obs_source_t-OBS_SOURCE_TYPE_INPUT) had the wrong kind.
    ResourceNotConfigurable = 606, -- The resource does not support being configured. This is particularly relevant to transitions, where they do not always have changeable settings.
    InvalidFilterKind = 607, -- The specified filter (obs_source_t-OBS_SOURCE_TYPE_FILTER) had the wrong kind.
    ResourceCreationFailed = 700, -- Creating the resource failed.
    ResourceActionFailed = 701, -- Performing an action on the resource failed.
    RequestProcessingFailed = 702, -- Processing the request failed unexpectedly. Note: A comment is required to be provided by obs-websocket.
    CannotAct = 703 -- -- The combination of request fields cannot be used to perform an action.
}

-- BTW did not validate all of these yet
local EventSubscriptionBitFlagsUnvalidated = {
    None = 0,
    General = 1,
    Config = 2,
    Scenes = 4,
    Inputs = 8,
    Transitions = 16,
    Filters = 32,
    Outputs = 64,
    SceneItems = 128,
    MediaInputs = 256,
    Vendors = 512,
    Ui = 1024,
    All = 2047, -- (1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024)
    InputVolumeMeters = 65536,
    InputActiveStateChanged = 131072,
    InputShowStateChanged = 262144,
    SceneItemTransformChanged = 524288
}

ObsMediaInputActionUnvalidated = {
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NONE = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NONE",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_STOP = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_STOP",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NEXT = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NEXT",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PREVIOUS = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PREVIOUS"
}

ObsOutputStateUnvalidated = {
    OBS_WEBSOCKET_OUTPUT_UNKNOWN = "OBS_WEBSOCKET_OUTPUT_UNKNOWN",
    OBS_WEBSOCKET_OUTPUT_STARTING = "OBS_WEBSOCKET_OUTPUT_STARTING",
    OBS_WEBSOCKET_OUTPUT_STARTED = "OBS_WEBSOCKET_OUTPUT_STARTED",
    OBS_WEBSOCKET_OUTPUT_STOPPING = "OBS_WEBSOCKET_OUTPUT_STOPPING",
    OBS_WEBSOCKET_OUTPUT_STOPPED = "OBS_WEBSOCKET_OUTPUT_STOPPED",
    OBS_WEBSOCKET_OUTPUT_RECONNECTING = "OBS_WEBSOCKET_OUTPUT_RECONNECTING",
    OBS_WEBSOCKET_OUTPUT_RECONNECTED = "OBS_WEBSOCKET_OUTPUT_RECONNECTED",
    OBS_WEBSOCKET_OUTPUT_PAUSED = "OBS_WEBSOCKET_OUTPUT_PAUSED",
    OBS_WEBSOCKET_OUTPUT_RESUMED = "OBS_WEBSOCKET_OUTPUT_RESUMED"
}
local function print_json(message, table)
    print(message, json.encode(table, { indent = true }))
end
local function error_unexpected_response(response)
    error("Received unexpected response: " .. json.encode(response, { indent = true }))
end

local function encode64(input)
    -- see comments in sha256 about io.popen peculiarities
    local cmd = "echo " .. string.format("%q", input) .. ' | tr -d "\n" | base64'
    print("  encode64 cmd:", cmd)
    local pipe = io.popen(cmd, "r")
    local result = pipe:read("*a")
    pipe:close()
    return result:gsub("\n$", "")
end

local function sha256(input)
    -- FYI io.popen DOES NOT PARSE LIKE A SHELL... if I pass "echo -n foobar" it results in "-n foobar" in the output?!?
    --   but it then does allow piping to other commands... WTF?
    --   printf would be another choice if issues with echo
    --   BE VERY CAREFUL ABOUT HOW YOU ALTER THIS CODE
    -- --quiet strips the trailing - (filename) which is STDOUT...
    --   strip \n added by echo since I cannot pass -n to echo here
    local cmd = "echo " .. string.format("%q", input) .. ' | tr -d "\n" | /sbin/sha256sum --quiet'
    print("  sha256 cmd:", cmd)
    local pipe = io.popen(cmd, "r")
    local result = pipe:read("*a")
    print("  sha256 result:", result)
    pipe:close()
    return result:gsub("\n$", "")
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
    if response.op ~= WebSocketOpCode.Hello then
        error_unexpected_response(response)
    end
    print_json("Received Hello", response)

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
        response = receive(ws)
        if response.op ~= WebSocketOpCode.Identified then
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
        -- https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#creating-an-authentication-string

        -- Concatenate the websocket password with the salt provided by the server (password + salt)
        local salt = hello.d.authentication.salt
        print("salt:", salt)
        -- salt = salt:gsub("=$", "")
        -- print("  salt:", salt)
        local password_plus_salt = password .. salt
        print("  password_plus_salt:", password_plus_salt)

        -- Generate an SHA256 binary hash of the result and base64 encode it, known as a base64 secret.
        local pps_hash = sha256(password_plus_salt)
        print("pps_hash:", pps_hash)
        local base64_secret = encode64(pps_hash)
        print("  base64_secret:", base64_secret)

        -- Concatenate the base64 secret with the challenge sent by the server (base64_secret + challenge)
        local challenge = hello.d.authentication.challenge
        -- print("  challenge:", challenge)
        -- challenge = challenge:gsub("=$", "")
        print("    challenge:", challenge)
        local base64_secret_plus_challenge = base64_secret .. challenge
        print("  base64_secret_plus_challenge:", base64_secret_plus_challenge)
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
        op = WebSocketOpCode.Identify,
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
        op = WebSocketOpCode.Request,
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
