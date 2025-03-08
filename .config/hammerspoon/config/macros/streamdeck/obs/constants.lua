
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
    Unknown = 0,                                -- Unknown status, should never be used.
    NoError = 10,                               -- For internal use to signify a successful field check.
    Success = 100,                              -- The request has succeeded.
    MissingRequestType = 203,                   -- The requestType field is missing from the request data.
    UnknownRequestType = 204,                   -- The request type is invalid or does not exist.
    GenericError = 205,                         -- Generic error code. Note: A comment is required to be provided by obs-websocket.
    UnsupportedRequestBatchExecutionType = 206, -- The request batch execution type is not supported.
    NotReady = 207,                             -- The server is not ready to handle the request. Note: This usually occurs during OBS scene collection change or exit. Requests may be tried again after a delay if this code is given.
    MissingRequestField = 300,                  -- A required request field is missing.
    MissingRequestData = 301,                   -- The request does not have a valid requestData object.
    InvalidRequestField = 400,                  -- Generic invalid request field message. Note: A comment is required to be provided by obs-websocket.
    InvalidRequestFieldType = 401,              -- A request field has the wrong data type.
    RequestFieldOutOfRange = 402,               -- A request field (number) is outside of the allowed range.
    RequestFieldEmpty = 403,                    -- A request field (string or array) is empty and cannot be.
    TooManyRequestFields = 404,                 -- There are too many request fields (eg. a request takes two optionals, where only one is allowed at a time).
    OutputRunning = 500,                        -- An output is running and cannot be in order to perform the request.
    OutputNotRunning = 501,                     -- An output is not running and should be.
    OutputPaused = 502,                         -- An output is paused and should not be.
    OutputNotPaused = 503,                      -- An output is not paused and should be.
    OutputDisabled = 504,                       -- An output is disabled and should not be.
    StudioModeActive = 505,                     -- Studio mode is active and cannot be.
    StudioModeNotActive = 506,                  -- Studio mode is not active and should be.
    ResourceNotFound = 600,                     -- The resource was not found. Note: Resources are any kind of object in obs-websocket, like inputs, profiles, outputs, etc.
    ResourceAlreadyExists = 601,                -- The resource already exists.
    InvalidResourceType = 602,                  -- The type of resource found is invalid.
    NotEnoughResources = 603,                   -- There are not enough instances of the resource in order to perform the request.
    InvalidResourceState = 604,                 -- The state of the resource is invalid. For example, if the resource is blocked from being accessed.
    InvalidInputKind = 605,                     -- The specified input (obs_source_t-OBS_SOURCE_TYPE_INPUT) had the wrong kind.
    ResourceNotConfigurable = 606,              -- The resource does not support being configured. This is particularly relevant to transitions, where they do not always have changeable settings.
    InvalidFilterKind = 607,                    -- The specified filter (obs_source_t-OBS_SOURCE_TYPE_FILTER) had the wrong kind.
    ResourceCreationFailed = 700,               -- Creating the resource failed.
    ResourceActionFailed = 701,                 -- Performing an action on the resource failed.
    RequestProcessingFailed = 702,              -- Processing the request failed unexpectedly. Note: A comment is required to be provided by obs-websocket.
    CannotAct = 703                             -- -- The combination of request fields cannot be used to perform an action.
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

