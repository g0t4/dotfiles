local PushButton = require("config.macros.streamdeck.pushButton")
local connectAndAuthenticate = require("config.macros.streamdeck.obs.connect").connectAndAuthenticate
local json = require("dkjson")
require("config.macros.streamdeck.obs.constants")
require("config.macros.streamdeck.obs.helpers")

---@class ToggleRecordButton : PushButton
local ToggleRecordButton = setmetatable({}, { __index = PushButton })


local offIcon = hsIcon("test-svgs/hanging-96.png")
local onIcon = hsIcon("test-svgs/upright2-64.png")

---@param buttonNumber integer
---@param deck DeckController
---@return ToggleRecordButton
function ToggleRecordButton:new(buttonNumber, deck)
    ---@class ToggleRecordButton
    local o = PushButton.new(ToggleRecordButton, buttonNumber, deck, offIcon)
    return o
end

local function updateIcon(self)
    hs.timer.doAfter(0.01, function()
        local status = Record.status()
        if status.outputActive then
            self.image = onIcon
        else
            self.image = offIcon
        end
        self.deck.hsdeck:setButtonImage(self.buttonNumber, self.image)
    end)
end

function ToggleRecordButton:start()
    -- todo get current state and show that icon (do in background)
    -- self.deck.hsdeck:setButtonImage(self.buttonNumber, self.image)
    updateIcon(self)
    do return end -- !!! COMMENT OUT TO ENABLE

    local setIconFromEvent = function(eventData)
        -- "eventData":{
        --   "outputActive":false,
        --   "outputState":"OBS_WEBSOCKET_OUTPUT_STOPPING"
        -- },
        -- "eventData":{
        --   "outputPath":"/Users/wesdemos/.../2025-03-08 17-20.mkv",
        --   "outputActive":false,
        --   "outputState":"OBS_WEBSOCKET_OUTPUT_STOPPED"
        -- },
        -- "eventData":{
        --   "outputActive":false,
        --   "outputState":"OBS_WEBSOCKET_OUTPUT_STARTING"
        -- },
        -- "eventData":{
        --   "outputPath":"/Users/wesdemos/.../2025-03-08 17-24.mkv",
        --   "outputActive":true,
        --   "outputState":"OBS_WEBSOCKET_OUTPUT_STARTED"
        -- },
        if eventData.outputActive then
            self.image = onIcon
        else
            self.image = offIcon
        end
        self.deck.hsdeck:setButtonImage(self.buttonNumber, self.image)
    end

    local eventFlags = EventSubscriptionBitFlags.Outputs
    local ws = connectAndAuthenticate(eventFlags)
    self.ws = ws

    local function checkForOutputs()
        self.currentTimer = nil
        local textFrame, binaryFrame, err, errorCode = ws_receive(ws, 1)
        if errorCode == 1001 then
            print("obs quit, stopping listening")
            ws:close()
            return
        end
        local delay = 0.5
        if errorCode == 60 then
            -- print("timeout, ignoring...")
            self.currentTimer = hs.timer.doAfter(delay, checkForOutputs)
            return
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
            printJson("evt", decoded)
            if decoded.d.eventType == "RecordStateChanged" then
                setIconFromEvent(decoded.d.eventData)
            end
            -- PRN? if just got a message, immediately check for more?
        end
        print("nothing received yet")
        self.currentTimer = hs.timer.doAfter(delay, checkForOutputs)
    end
    self.currentTimer = hs.timer.doAfter(0.1, checkForOutputs)
end

function ToggleRecordButton:stop()
    if self.currentTimer then
        self.currentTimer:stop()
        self.currentTimer = nil
    end
    if self.ws then
        print("closing websocket")
        self.ws:close()
        self.ws = nil
    end
end

function ToggleRecordButton:pressed()
    Record.toggle()
    updateIcon(self)
end

function ToggleRecordButton:__tostring()
    return "ToggleRecordButton: " .. (self.buttonNumber or "nil")
end

return ToggleRecordButton
