--

-- !!! using hs.window.filter breaks all hs.axuielement.observer.notifications
do return end -- !!! REMOVE if you are ok with breaking observers
-- FYI hs.application.watcher still works (i use for app switch notifications)
--   JUST LOADING the module alone breaks things (even if after setup observers)
-- *** ISSUE I REPORTED: https://github.com/Hammerspoon/hammerspoon/issues/3754
local wf = hs.window.filter

--- FYI! window.filter felt sluggish so maybe not end of world that it is buggy (and the docs mention it is gonna be bugg)


local braveWindows = wf.new { APPS.BraveBrowserBeta }
-- local allWindows = wf.new(true)
-- print("braveWindows", hs.inspect(braveWindows))

-- -- https://www.hamierspoon.org/docs/hs.window.filter.html#subscribe
-- braveWindows:subscribe(hs.window.filter.windowFocused,
--     ---@param hsWin hs.window
--     ---@param appName string
--     ---@param event string
--     function(hsWin, appName, event)
--         print("windowFocused", hs.inspect(hsWin))
--         -- could also use window changes to trigger app profile reloads... though not if its way slower
--         local winTitle = hsWin:title()
--         print("  winTitle", winTitle)
--     end)

braveWindows:subscribe(hs.window.filter.windowTitleChanged,
    ---@param hsWin hs.window
    ---@param appName string
    ---@param event string
    function(hsWin, appName, event)
        print("windowTitleChanged", hs.inspect(hsWin))
        -- local winTitle = hsWin:title()
        -- print("  winTitle:", winTitle)
        -- btw the notice may be slightly delayed, the print to console takes about a second after I change tabs/sites in browser
        -- "Google Docs - Brave Beta - demos" => even has profiles
        --   can use this to trigger a profile reload (like page/app change)
        --     for one deck (or multiple)
        --     based on registered profile page modifications (sets of buttons)
        --
        -- Also, when loading profiles normally I would just read env (window titles) to load profile mods...
        --   so all I really need is a trigger to reload profiles
    end)

return braveWindows
