require("config.macros.buttons.helpers")

-- various types for holding sets of buttons
--
-- XLPage => 8 cols x 4 rows - 96x96
-- PlusPage => 4cols x 2 rows - 120x120 (IIRC)
-- PlusEncoderPage => 4 encoders (one screen each, plus dial)
--

-- @classmod ButtonPage
-- @field buttonNumber number
-- @field deck hs.streamdeck
-- @field image string
-- @field macro string
-- @field param string|nil
local ButtonPage = {}
ButtonPage.__index = ButtonPage

function ButtonPage:new(deck, rows, cols)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- TODO do I need the deck here?
    o.deck = deck
    o.rows = rows
    o.cols = cols
    o.buttons = {}
    return o
end

function ButtonPage:addButton(buttonNumber, button)
    self.buttons[buttonNumber] = button
end

function ButtonPage:start()
    for rowNumber = 1, self.rows do
        for colNumber = 1, self.cols do
            local buttonNumber = rowNumber * self.cols + colNumber
            local button = self.buttons[buttonNumber]
            if button then
                button:start()
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
                resetButton(buttonNumber, self.deck)
            end
        end
        verbose("exec Page: " .. rowNumber .. " " .. colNumber)
    end
end

function ButtonPage:stop()
    -- for now just call stop on all buttons... to stop dynamic updates
    -- PRN and mark smth to stop reacting to keypresses
    for buttonNumber, button in pairs(self.buttons) do
        button:stop()
    end
end
