local wf = hs.window.filter

-- local braveWindows = wf.new { "Brave Browser Beta" }
local braveWindows = wf.new(true)
print("braveWindows", hs.inspect(braveWindows))

print("testWindowsFilters")

-- https://www.hamierspoon.org/docs/hs.window.filter.html#subscribe
braveWindows:subscribe(hs.window.filter.windowFocused,
    ---@param hsWin hs.window
    ---@param appName string
    ---@param event string
    function(hsWin, appName, event)
        print("windowFocused", hs.inspect(hsWin))
        local winTitle = hsWin:title()
        print("  winTitle", winTitle)
    end)

braveWindows:subscribe(hs.window.filter.windowTitleChanged,
    ---@param hsWin hs.window
    ---@param appName string
    ---@param event string
    function(hsWin, appName, event)
        print("windowTitleChanged", hs.inspect(hsWin))
        local winTitle = hsWin:title()
        print("  winTitle", winTitle)
    end)

return braveWindows
