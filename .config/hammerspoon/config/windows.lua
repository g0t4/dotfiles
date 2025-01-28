local tripleModifiers = { "cmd", "shift", "ctrl" }
local doubleModifiers = { "cmd", "shift" }
hs.loadSpoon("WinWin")
hs.hotkey.bind(tripleModifiers, "Right", function()
    -- leave this as right only, no bounce... only so I can see if I start using right... cuz I bet with bounce I will just use left exclusively since that's all I was using before
    spoon.WinWin:moveToScreen("right")
end)
hs.hotkey.bind(tripleModifiers, "Left", function()
    -- SUPER cool to see most logic resides in hs.screen/hs.window... I don't really even need WinWin/WIndowHalfsAndThirds

    -- FYI can impl smth like hs.screen.toWest() but would need to find the furthest west screen
    --    https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/screen/screen.lua#L305-L342
    -- HONESTLY I only have two screens at most so I don't care that much :) do the bounce until I have 3

    local win = hs.window.focusedWindow()
    local beforeScreen = win:screen()
    spoon.WinWin:moveToScreen("left")
    local afterScreen = win:screen()
    if beforeScreen ~= afterScreen then
        return
    end
    -- bound back when on leftmost, mirror what I got used to with bettersnap (albeit this is not cycling but bouncing)
    spoon.WinWin:moveToScreen("right")
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


-- WIP SCREENSHOTS
--

if false then
    hs.hotkey.bind({ "shift", "cmd" }, "3", function()
        local screen = hs.screen.mainScreen()
        local filename = os.date("%Y-%m-%d_%I-%M-%S-%p_Screenshot.png")
        local snapshots_dir = os.getenv("HOME") .. "/Pictures/Screencaps"
        local filePath = snapshots_dir .. "/" .. filename
        -- screen:shotAsPNG(filePath)
        -- 3840 × 2160
        -- 7680 × 4320 -- literally saving an 8k image! why?!
        -- TODO => size is HUGE ... need to compress it with smth like imagemagick/convert

        -- instead take in-memory snapshot I can manipulate
        local snap = screen:snapshot() -- TODO rect param
        print("snap", hs.inspect(snap))
        print("size", hs.inspect(snap:size())) -- 4k size initially...
        -- croppedCopy()
        -- saveToFile()
        -- setSize()
        -- print("ascii\n", snap:toASCII())
        --
        --
        -- OK much better 4k resolution now (even though it says 2k here after divide by 2... it is retina at 2k so 4k effective pixels)... 4MB instead of 11MB
        --   STILL TOO BIG THOUGH... would need to further compress (i.e. imagemagick => do that later)
        local half = snap:setSize({
            w = snap:size().w / 2,
            h = snap:size().h / 2
        })
        half:saveToFile(filePath)
    end)
end
