--

-- !!! using hs.window.filter breaks all hs.axuielement.observer.notifications
do return end -- !!! REMOVE if you are ok with breaking observers
-- FYI hs.application.watcher still works (i use for app switch notifications)
--   JUST LOADING the module alone breaks things (even if after setup observers)
-- *** ISSUE I REPORTED: https://github.com/Hammerspoon/hammerspoon/issues/3754
local wf = hs.window.filter

-- ! hs.window.filters IS NOT SLOW, the title of the web browser only changes after the page LOADS!
--    its often fast when a page loads fast, slow otherwise!
--    but, I won't be using any buttons until the page is loaded anyways, so NBD!


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
--         -- could also use window changes to trigger app profile reloads...
--         local winTitle = hsWin:title()
--         print("  winTitle", winTitle)
--     end)

braveWindows:subscribe(hs.window.filter.windowTitleChanged,
    ---@param hsWin hs.window
    ---@param appName string
    ---@param event string
    function(hsWin, appName, event)
        print("windowTitleChanged", hs.inspect(hsWin))
        local winTitle = hsWin:title()
        print("  winTitle:", winTitle)
        -- "Google Docs - Brave Beta - demos" => even has profiles
    end)

return braveWindows
