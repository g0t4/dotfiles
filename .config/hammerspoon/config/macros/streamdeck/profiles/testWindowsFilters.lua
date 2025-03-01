local wf = hs.window.filter

local braveWindows = wf.new { "Brave Browser Beta" }
-- local allWindows = wf.new(true)
print("braveWindows", hs.inspect(braveWindows))

print("testWindowsFilters")

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
    end)

return braveWindows
