require("config.macros.buttons.textToImage")
PushButton = require("config.macros.buttons.push")

local function getTimeImage()
    local now = os.date("%H:%M")
    local date = os.date("%a\n%b %d")
    -- https://www.lua.org/pil/22.1.html
    return drawTextIcon(now .. "\n" .. date)
end

---@class ClockButton : PushButton
---@field lastTime string|nil
---@field timer hs.timer
local ClockButton = setmetatable({}, { __index = PushButton }) -- ClockButton inherits PushButton funcs
-- FYI metatable MUST have __index defined (table/func) to use it for lookups
--    THAT SAID, { __index = PushButton } is redundant since PushButton.__index = PushButton (already)
-- FTR foo.__index is not used for lookups, getmetatable(foo).__index is used
-- ClockButton.__index = ClockButton -- Ensure ClockButton can be used as a metatable directly
--  I find setting __index confusing, instead just always use { __index = metatable }

---@param buttonNumber number
---@param deck hs.streamdeck
---@return ClockButton
function ClockButton:new(buttonNumber, deck)
    -- mark return type as ClockButton so luals doesn't complain about setting fields below
    ---@class ClockButton
    local o = PushButton.new(ClockButton, buttonNumber, deck)
    -- FYI new(self would allow subclassing ClockButton, but I won't do that until I need it
    -- FYI PushButton:new(...) == PushButton.new(PushButton, ...)
    -- Thus I override and pass ClockButton instead (as the implicit self param)
    --   thus setmetatable in PushButton sets the metatable for me
    --   or, I could use:
    -- setmetatable(o, ClockButton) -- REDUNDANT, but would not hurt if done again

    -- add fields specific to ClockButton
    o.testMyOwnField = "foo" -- when testing field inheritance, uncomment this
    o.lastTime = nil
    o.timer = hs.timer.doEvery(10, function()
        -- FYI this is a good case where button needs to know its deck/number to update the image!
        local now = os.date("%H:%M")
        if o.lastTime ~= nil and o.lastTime == now then
            return
        end
        deck:setButtonImage(buttonNumber, getTimeImage())
    end)
    return o
end

function ClockButton:start()
    self.timer:start()
    self.timer:fire()
end

function ClockButton:stop()
    -- todo mechanism to stop/cleanup timer if button removed
    -- FYI let something else handle reset on the button image, behavior, etc
    self.timer:stop()
end

-- tests to ensure I setup inheritance properly:
function ClockButton:specialForTesting()
end

local clockTest = ClockButton:new(1, {})
print("clockTest:", hs.inspect(clockTest)) -- should show fields of both ClockButton and PushButton
print("getmetatable(clockTest):", hs.inspect(getmetatable(clockTest)))
print("  metatable(clockTest) == PushButton", getmetatable(clockTest) == PushButton)
print("  metatable(clockTest) == ClockButton", getmetatable(clockTest) == ClockButton)
print("2x getmetatable(clockTest):", hs.inspect(getmetatable(getmetatable(clockTest))))
-- make sure all of these say true (would've used asssertions but those sucked to troubleshoot)
-- inherits funcs from PushButton:
assert(type(clockTest.pressed) == "function", "clockTest.pressed is a function")
assert(clockTest.pressed == PushButton.pressed, "clockTest.pressed is inherited")
-- keeps its own functions:
assert(type(clockTest.specialForTesting) == "function", "clockTest.specialForTesting is a function")
assert(clockTest.specialForTesting == ClockButton.specialForTesting, "still has clockTest.specialForTesting")
-- has its own fields:
-- NOTE add this field for testing b/c ClockButton by default won't have a good field to test initially
assert(clockTest.testMyOwnField == "foo", "clockTest.testMyOwnField is set to 'foo'")
-- inerhits fields (and they are set) from PushButton:
assert(clockTest.buttonNumber == 1, "clockTest.buttonNumber is set to 1")




return ClockButton
