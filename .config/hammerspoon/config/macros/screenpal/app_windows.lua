local ToolBarWindow = require("config.macros.screenpal.windows.tools_window")

---@class AppWindows
---@field app hs.axuielement
local AppWindows = {}
AppWindows.__index = AppWindows

--- Right now this is basically a wrapper around using a cached list of windows
--- and then refresh them if needed on window lookup (by title)
---@param app hs.axuielement
function AppWindows.new(app)
    local o = setmetatable({}, AppWindows)
    o.app = app
    o.windows_by_title = {}
    return o
end

function AppWindows:_refresh()
    -- FTR refresh takes 5-11ms (not terrible) so its not a huge time savings except maybe when aggregated with other savings
    local start = get_time()
    local windows = self.app:windows()
    local new_cache = {}
    for _, win in ipairs(windows) do
        local title = win:axTitle()
        new_cache[title] = win
    end
    self.windows_by_title = new_cache
    -- print_took("  refresh took", start)
end

function AppWindows:_ensure_loaded()
    local any_windows_loaded = #self.windows_by_title == 0
    if any_windows_loaded then
        self:_refresh()
    end
end

function AppWindows:get_tool_window()
    return ToolBarWindow.new(self)
end

---@param lookup_fn function # function that returns the window from the cache
---@return hs.axuielement? editor_window
function AppWindows:_find_window(lookup_fn)
    self:_ensure_loaded()
    local win = lookup_fn()
    -- crude, for now the window you want to lookup, if it is not valid anymore then try refresh cache
    if not win or not win:isValid() then
        -- one attempt to refresh if not found or invalid
        -- rare to ask for non-existant window, so it's fine as a fallback (s/b rare to hit)
        self:_refresh()
        win = lookup_fn()
    end
    return win
end

---@param titlePattern string # lua pattern
---@return hs.axuielement? editor_window
function AppWindows:get_window_by_title_pattern(titlePattern)
    local function lookup_by_pattern()
        return self:_get_window_by_title_pattern(titlePattern)
    end
    return self:_find_window(lookup_by_pattern)
end

---@param titlePattern string # lua pattern
---@return hs.axuielement? editor_window
function AppWindows:_get_window_by_title_pattern(titlePattern)
    for title, win in pairs(self.windows_by_title) do
        if title:match(titlePattern) then
            return win
        end
    end
end

---@return hs.axuielement editor_window
function AppWindows:editor_window_or_throw()
    local win = self:get_window_by_title_pattern("^ScreenPal -")
    if win then return win end
    error("No Screenpal editor window found")
end

---@param window_object table # the window wrapper object
---@param title string # exact title to match
---@return hs.axuielement? editor_window
function AppWindows:get_window_by_title(window_object, title)
    local function lookup_by_exact_title()
        return self.windows_by_title[title]
    end

    -- TODO review all window wrappers that cached their window `_win` and port to use this (or by title pattern above)
    -- rely on cache of windows here on AppWindows and not need to cache each window on other window wrappers!
    --  much cleaner cache architecture
    --  just have the window wrappers call into here to get window any time it needs a reference to its window (cheap)
    local win = self:_find_window(lookup_by_exact_title)
    window_object._win = win
    return win
end

return AppWindows
