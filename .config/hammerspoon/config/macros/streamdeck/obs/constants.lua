_G.WebSocketOpCode = {
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

_G.WebSocketCloseCode = {
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

_G.RequestBatchExecutionType = {
    None = -1,
    SerialRealtime = 0,
    SerialFrame = 1,
    Parallel = 2,
}

_G.RequestStatusUnvalidated = {
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
_G.EventSubscriptionBitFlagsUnvalidated = {
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

_G.ObsMediaInputActionUnvalidated = {
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NONE = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NONE",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_STOP = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_STOP",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NEXT = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_NEXT",
    OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PREVIOUS = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PREVIOUS"
}

_G.ObsOutputStateUnvalidated = {
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

_G.Requests = {
    General = {
        GetVersion = "GetVersion",
        GetStats = "GetStats",
        BroadcastCustomEvent = "BroadcastCustomEvent",
        CallVendorRequest = "CallVendorRequest",
        GetHotkeyList = "GetHotkeyList",
        TriggerHotkeyByName = "TriggerHotkeyByName",
        TriggerHotkeyByKeySequence = "TriggerHotkeyByKeySequence",
        Sleep = "Sleep"
    },
    Config = {
        GetPersistentData = "GetPersistentData",
        SetPersistentData = "SetPersistentData",
        GetSceneCollectionList = "GetSceneCollectionList",
        SetCurrentSceneCollection = "SetCurrentSceneCollection",
        CreateSceneCollection = "CreateSceneCollection",
        GetProfileList = "GetProfileList",
        SetCurrentProfile = "SetCurrentProfile",
        CreateProfile = "CreateProfile",
        RemoveProfile = "RemoveProfile",
        GetProfileParameter = "GetProfileParameter",
        SetProfileParameter = "SetProfileParameter",
        GetVideoSettings = "GetVideoSettings",
        SetVideoSettings = "SetVideoSettings",
        GetStreamServiceSettings = "GetStreamServiceSettings",
        SetStreamServiceSettings = "SetStreamServiceSettings",
        GetRecordDirectory = "GetRecordDirectory",
        SetRecordDirectory = "SetRecordDirectory"
    },
    Sources = {
        GetSourceActive = "GetSourceActive",
        GetSourceScreenshot = "GetSourceScreenshot",
        SaveSourceScreenshot = "SaveSourceScreenshot"
    },
    Scenes = {
        GetSceneList = "GetSceneList",
        GetGroupList = "GetGroupList",
        GetCurrentProgramScene = "GetCurrentProgramScene",
        SetCurrentProgramScene = "SetCurrentProgramScene",
        GetCurrentPreviewScene = "GetCurrentPreviewScene",
        SetCurrentPreviewScene = "SetCurrentPreviewScene",
        CreateScene = "CreateScene",
        RemoveScene = "RemoveScene",
        SetSceneName = "SetSceneName",
        GetSceneSceneTransitionOverride = "GetSceneSceneTransitionOverride",
        SetSceneSceneTransitionOverride = "SetSceneSceneTransitionOverride"
    },
    Inputs = {
        GetInputList = "GetInputList",
        GetInputKindList = "GetInputKindList",
        GetSpecialInputs = "GetSpecialInputs",
        CreateInput = "CreateInput",
        RemoveInput = "RemoveInput",
        SetInputName = "SetInputName",
        GetInputDefaultSettings = "GetInputDefaultSettings",
        GetInputSettings = "GetInputSettings",
        SetInputSettings = "SetInputSettings",
        GetInputMute = "GetInputMute",
        SetInputMute = "SetInputMute",
        ToggleInputMute = "ToggleInputMute",
        GetInputVolume = "GetInputVolume",
        SetInputVolume = "SetInputVolume",
        GetInputAudioBalance = "GetInputAudioBalance",
        SetInputAudioBalance = "SetInputAudioBalance",
        GetInputAudioSyncOffset = "GetInputAudioSyncOffset",
        SetInputAudioSyncOffset = "SetInputAudioSyncOffset",
        GetInputAudioMonitorType = "GetInputAudioMonitorType",
        SetInputAudioMonitorType = "SetInputAudioMonitorType",
        GetInputAudioTracks = "GetInputAudioTracks",
        SetInputAudioTracks = "SetInputAudioTracks",
        GetInputDeinterlaceMode = "GetInputDeinterlaceMode",
        SetInputDeinterlaceMode = "SetInputDeinterlaceMode",
        GetInputDeinterlaceFieldOrder = "GetInputDeinterlaceFieldOrder",
        SetInputDeinterlaceFieldOrder = "SetInputDeinterlaceFieldOrder",
        GetInputPropertiesListPropertyItems = "GetInputPropertiesListPropertyItems",
        PressInputPropertiesButton = "PressInputPropertiesButton"
    },
    Transitions = {
        GetTransitionKindList = "GetTransitionKindList",
        GetSceneTransitionList = "GetSceneTransitionList",
        GetCurrentSceneTransition = "GetCurrentSceneTransition",
        SetCurrentSceneTransition = "SetCurrentSceneTransition",
        SetCurrentSceneTransitionDuration = "SetCurrentSceneTransitionDuration",
        SetCurrentSceneTransitionSettings = "SetCurrentSceneTransitionSettings",
        GetCurrentSceneTransitionCursor = "GetCurrentSceneTransitionCursor",
        TriggerStudioModeTransition = "TriggerStudioModeTransition",
        SetTBarPosition = "SetTBarPosition"
    },
    Filters = {
        GetSourceFilterKindList = "GetSourceFilterKindList",
        GetSourceFilterList = "GetSourceFilterList",
        GetSourceFilterDefaultSettings = "GetSourceFilterDefaultSettings",
        CreateSourceFilter = "CreateSourceFilter",
        RemoveSourceFilter = "RemoveSourceFilter",
        SetSourceFilterName = "SetSourceFilterName",
        GetSourceFilter = "GetSourceFilter",
        SetSourceFilterIndex = "SetSourceFilterIndex",
        SetSourceFilterSettings = "SetSourceFilterSettings",
        SetSourceFilterEnabled = "SetSourceFilterEnabled"
    },
    SceneItems = {
        GetSceneItemList = "GetSceneItemList",
        GetGroupSceneItemList = "GetGroupSceneItemList",
        GetSceneItemId = "GetSceneItemId",
        GetSceneItemSource = "GetSceneItemSource",
        CreateSceneItem = "CreateSceneItem",
        RemoveSceneItem = "RemoveSceneItem",
        DuplicateSceneItem = "DuplicateSceneItem",
        GetSceneItemTransform = "GetSceneItemTransform",
        SetSceneItemTransform = "SetSceneItemTransform",
        GetSceneItemEnabled = "GetSceneItemEnabled",
        SetSceneItemEnabled = "SetSceneItemEnabled",
        GetSceneItemLocked = "GetSceneItemLocked",
        SetSceneItemLocked = "SetSceneItemLocked",
        GetSceneItemIndex = "GetSceneItemIndex",
        SetSceneItemIndex = "SetSceneItemIndex",
        GetSceneItemBlendMode = "GetSceneItemBlendMode",
        SetSceneItemBlendMode = "SetSceneItemBlendMode"
    },
    Outputs = {
        GetVirtualCamStatus = "GetVirtualCamStatus",
        ToggleVirtualCam = "ToggleVirtualCam",
        StartVirtualCam = "StartVirtualCam",
        StopVirtualCam = "StopVirtualCam",
        GetReplayBufferStatus = "GetReplayBufferStatus",
        ToggleReplayBuffer = "ToggleReplayBuffer",
        StartReplayBuffer = "StartReplayBuffer",
        StopReplayBuffer = "StopReplayBuffer",
        SaveReplayBuffer = "SaveReplayBuffer",
        GetLastReplayBufferReplay = "GetLastReplayBufferReplay",
        GetOutputList = "GetOutputList",
        GetOutputStatus = "GetOutputStatus",
        ToggleOutput = "ToggleOutput",
        StartOutput = "StartOutput",
        StopOutput = "StopOutput",
        GetOutputSettings = "GetOutputSettings",
        SetOutputSettings = "SetOutputSettings"
    },
    Stream = {
        GetStreamStatus = "GetStreamStatus",
        ToggleStream = "ToggleStream",
        StartStream = "StartStream",
        StopStream = "StopStream",
        SendStreamCaption = "SendStreamCaption"
    },
    Record = {
        GetRecordStatus = "GetRecordStatus",
        ToggleRecord = "ToggleRecord",
        StartRecord = "StartRecord",
        StopRecord = "StopRecord",
        ToggleRecordPause = "ToggleRecordPause",
        PauseRecord = "PauseRecord",
        ResumeRecord = "ResumeRecord",
        SplitRecordFile = "SplitRecordFile",
        CreateRecordChapter = "CreateRecordChapter"
    },
    MediaInputs = {
        GetMediaInputStatus = "GetMediaInputStatus",
        SetMediaInputCursor = "SetMediaInputCursor",
        OffsetMediaInputCursor = "OffsetMediaInputCursor",
        TriggerMediaInputAction = "TriggerMediaInputAction"
    },
    Ui = {
        GetStudioModeEnabled = "GetStudioModeEnabled",
        SetStudioModeEnabled = "SetStudioModeEnabled",
        OpenInputPropertiesDialog = "OpenInputPropertiesDialog",
        OpenInputFiltersDialog = "OpenInputFiltersDialog",
        OpenInputInteractDialog = "OpenInputInteractDialog",
        GetMonitorList = "GetMonitorList",
        OpenVideoMixProjector = "OpenVideoMixProjector",
        OpenSourceProjector = "OpenSourceProjector"
    }
}
