local tripleModifiers = { "cmd", "shift", "ctrl" }
local doubleModifiers = { "cmd", "shift" }
hs.loadSpoon("WinWin")
hs.hotkey.bind(tripleModifiers, "Right", function()
    spoon.WinWin:moveToScreen("right")
end)
hs.hotkey.bind(tripleModifiers, "Left", function()
    -- now I can do left too (bettersnap only had cycle displays key)
    spoon.WinWin:moveToScreen("left")
    -- PRN if cannot move to the left, cycle to the right most display? or let it stop as it is now?
end)


hs.loadSpoon("WindowHalfsAndThirds")
spoon.WindowHalfsAndThirds:bindHotkeys({

    -- toggles max (improvement over bettersnap which only does max)
    max_toggle = {
        tripleModifiers,
        "Up",
    },

    -- *** HABITUATE
    -- revert window change!!
    undo = {
        tripleModifiers,
        "Z",
    },

    -- halves:
    left_half = {
        doubleModifiers,
        "Left",
    },
    right_half = {
        doubleModifiers,
        "Right",
    },
    top_half = {
        doubleModifiers,
        "Up",
    },
    bottom_half = {
        doubleModifiers,
        "Down",
    },

    -- quarters:
    top_left = {
        tripleModifiers,
        "Pad7",
    },
    top_right = {
        tripleModifiers,
        "Pad8",
    },
    bottom_left = {
        tripleModifiers,
        "Pad4",
    },
    bottom_right = {
        tripleModifiers,
        "Pad5",
    },

    -- For now, I don't think I will need these, esp b/c left/right above has three sizes each to adjust and that sounds good enough for what I might use thirds for
    --
    -- -- thirds:
    -- left_third = {
    --     tripleModifiers,
    --     "Pad1",
    -- },
    -- right_third = {
    --     tripleModifiers,
    --     "Pad2",
    -- },
    -- FYI I do not see a middle third binding?

})
