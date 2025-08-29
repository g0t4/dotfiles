require("config.macros.streamdeck.helpers")


---@class ButtonsController
---@field deck DeckController
---@field rows integer
---@field cols integer
---@field buttons table<integer, PushButton>
local ButtonsController = {}
ButtonsController.__index = ButtonsController


---@param deck DeckController
---@param rows integer
---@param cols integer
---@return ButtonsController
function ButtonsController:new(deck, rows, cols)
    local o = setmetatable({}, self)
    o.deck = deck
    o.rows = rows
    o.cols = cols
    o.buttons = {}
    return o
end

---@param deck DeckController
---@return ButtonsController
function ButtonsController:newXL(deck)
    return ButtonsController:new(deck, 4, 8)
end

---@param deck DeckController
---@return ButtonsController
function ButtonsController:newPlus(deck)
    return ButtonsController:new(deck, 2, 4)
end

---@param button PushButton
function ButtonsController:addButton(button)
    self.buttons[button.buttonNumber] = button
end

function ButtonsController:removeButtons()
    self.buttons = {}
end

---@param buttons PushButton[]
function ButtonsController:addButtons(buttons)
    for _, button in ipairs(buttons) do
        self:addButton(button)
    end
end

function ButtonsController:start()
    for buttonNumber = 1, self.rows * self.cols do
        local button = self.buttons[buttonNumber]
        if button then
            -- local startTime = get_time() -- TMP TIMING ANALYSIS
            button:start()
            -- if _G.LOG_DETAILED_TIMING then print("          start(" .. buttonNumber .. ") " .. GetElapsedTimeInMilliseconds(startTime) .. "ms") end -- TMP TIMING ANALYSIS
        else
            -- reset flashes the splash screen (very noticeable)
            -- but, changes w/o reset are not noticeable
            --   and set background black effectively resets (if it had smth previously)
            -- TODO when I set the color, is that using an image?
            --   if so is that at all slow if done for every "blank" button?
            --   if so maybe create the blank image?
            --     optimized for the button size too?
            --     i.e. 96x96 for XL, 120x120 for Plus
            --   measure perf of either approach

            -- TODO move this to a deck wrapper type that I can use to add my own deck logic
            -- i.e.:
            --   mydeck:resetButton(buttonNumber)
            -- resetButton(buttonNumber, self.deck.hsdeck)
            -- SUBSTANTIAL OVERHEAD TO do this on every not set button... lets pull that behavior out and use reset if needed be which is like instant!
        end
    end
end

function ButtonsController:resetButtons()
    -- local startTime = get_time()
    self:removeButtons() -- EMPTY the LIST of buttons
    self.deck.hsdeck:reset() -- ~0.3ms
    -- print("rm in", GetElapsedTimeInMilliseconds(startTime), "ms")

    -- TO get rid of elgato splash screen:
    -- => elgato app => prefs => devices => pick each deck => advanced btn (lower right)
    --   => standby screen => click set => drop transparent.svg... BAM!
    -- WHY reset?
    --  no holdover buttons
    --  avoid flicker from logo/standby screen
    --    by changing standby to blank, if you don't set any buttons on the deck, it won't show the standby screen!
    --    otherwise, the stock standy logo stays until first button is set after reset
    --      this also causes the logo flicker (albeit very fast)
    --  <1 ms to clear (vs 100ms to set each button to transparent)
    --    FYI it is possible that clear would be fast if I had the right image size
    --     TODO test image size and performance:
    --      I found code that appears to do a resize to button dimensions (can get from deck) => 96x96 for XL, 120x120 for Plus
    --      https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/streamdeck/HSStreamDeckDevice.m#L390
end

function ButtonsController:stop()
    -- for now just call stop on all buttons... to stop dynamic updates
    -- PRN and mark smth to stop reacting to keypresses
    for _, button in pairs(self.buttons) do
        button:stop()
    end
end

--- called when a button is pressed
---@param buttonNumber integer
---@param pressedOrReleased boolean
function ButtonsController:onButtonPressed(buttonNumber, pressedOrReleased)
    local button = self.buttons[buttonNumber]
    if not button then
        -- verbose("button not mapped: ", buttonNumber, "pressedOrReleased: ", pressedOrReleased)
        return
    end

    if pressedOrReleased then
        if button.pressed == nil then
            -- don't need to warn really b/c a button could be setup on release only...
            -- verbose("button does not have pressed method: ", buttonNumber)
            return
        end
        button:pressed()
        return
    end
    -- PRN else case... for triggering on release... use button.released in that case
end

return ButtonsController
