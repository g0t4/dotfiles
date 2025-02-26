require("config.macros.streamdeck.textToImage")
require("config.macros.streamdeck.helpers")
PushButton = require("config.macros.streamdeck.pushButton")

local function getTimeImage()
    local now = os.date("%H:%M")
    local date = os.date("%a\n%b %d")
    -- https://www.lua.org/pil/22.1.html
    return drawTextIcon(now .. "\n" .. date)
end

---@class ClockButton : PushButton
---@field lastTime string|nil
---@field timer hs.timer
local ClockButton = setmetatable({}, { __index = PushButton })
-- here is how you read the line above:
--  ClockButton is a new table w/ a metatable that has its __index set to PushButton
--  b/c {} doesn't have a metatable, so we're just attaching one right away
--  so, KeyStrokeButton inherits everything "static" from PushButton (i.e. functions)
-- FYI metatable MUST have __index defined (table/func) to use it for key lookups
--  getmetatable(foo).__index is used, NOT foo.__index
--
-- I find setting __index on regular tables confusing, instead just always use { __index = metatable }
--   so don't use this:
--     ClockButton.__index = ClockButton -- Ensure ClockButton can be used as a metatable directly
--   yes, there is an extra table of indirection, don't care if it helps me keep it straight for now

---@param buttonNumber number
---@param deck hs.streamdeck
---@return ClockButton
function ClockButton:new(buttonNumber, deck)
    -- mark return type as ClockButton so luals doesn't complain about setting fields below
    ---@class ClockButton
    local o = PushButton.new(ClockButton, buttonNumber, deck, nil)
    -- FTR `.new(self` would allow subclassing ClockButton, but I won't do that until I need it
    --   using `.new` to explicitly set `self`, otherwise (w/ : colon operator):
    --   PushButton:new(...) == PushButton.new(PushButton, ...)
    -- Thus I override and pass ClockButton instead (as the implicit self param)
    -- AND then setmetatable in PushButton:new sets the metatable for me
    --   or, I could use:
    -- setmetatable(o, ClockButton) -- REDUNDANT, but would not hurt if done again

    -- add fields specific to ClockButton
    -- TODO move this testing to unit tests... that way I don't have to leave it here
    o.testMyOwnField = "foo" -- when testing field inheritance, uncomment this
    o.lastTime = nil
    return o
end

function ClockButton:start()
    self.timer = hs.timer.doEvery(10, function()
        -- FYI this is a good case where button needs to know its deck/number to update the image!
        local now = os.date("%H:%M")
        if self.lastTime ~= nil and self.lastTime == now then
            return
        end
        self.deck:setButtonImage(self.buttonNumber, getTimeImage())
    end)
    self.timer:start()
    self.timer:fire()
end

function ClockButton:stop()
    -- todo mechanism to stop/cleanup timer if button removed
    -- FYI let something else handle reset on the button image, behavior, etc
    self.timer:stop()
end

function ClockButton:__tostring()
    -- this works by virtue of it being set in PushButton.new to self.__tostring which is this
    return "ClockButton: " .. (self.buttonNumber or "nil")
end

-- TESTING only:
-- keep these assertions for now b/c metatables + __index still throws me off and I need this to fallback on
--   especially as I flesh out my button hierarchy
--
function ClockButton:_specialForTesting()
end

-- TESTING only:
local clockTest = ClockButton:new(1, {})
-- assert(tostring(clockTest) == "ClockButton: 1")
-- inherits funcs from PushButton:
assert(type(clockTest.pressed) == "function", "clockTest.pressed is a function")
assert(clockTest.pressed == PushButton.pressed, "clockTest.pressed is inherited")
assert(type(clockTest.start) == "function", "clockTest.start is a function")
assert(clockTest.start == ClockButton.start, "clockTest.start is overridden")
-- keeps its own functions:
assert(type(clockTest._specialForTesting) == "function", "clockTest._specialForTesting is a function")
assert(clockTest._specialForTesting == ClockButton._specialForTesting, "still has clockTest._specialForTesting")
-- has its own fields:
-- NOTE add this field for testing b/c ClockButton by default won't have a good field to test initially
assert(clockTest.testMyOwnField == "foo", "clockTest.testMyOwnField is set to 'foo'")
-- inerhits fields (and they are set) from PushButton:
assert(clockTest.buttonNumber == 1, "clockTest.buttonNumber is set to 1")
--
ClockButton._specialForTesting = nil



return ClockButton
