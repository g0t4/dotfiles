---@class AppWindows
---@field app hs.axuielement
_G.AppWindows = {}
AppWindows.__index = AppWindows

---@param app hs.axuielement
function AppWindows:new(app)
    local self = setmetatable({}, AppWindows)
    self.app = app
    self.windows_by_title = {}
    return self
end

function AppWindows:_refresh()
    local start = GetTime()
    local windows = self.app:windows()
    local newCache = {}
    for _, win in ipairs(windows) do
        local title = win:axTitle()
        if title and title:match("^ScreenPal -") then
            newCache[title] = win
        end
    end
    self.windows_by_title = newCache
    PrintTook("refresh took", start)
end

function AppWindows:_ensure_loaded()
    local any_windows_loaded = #self.windows_by_title == 0
    if any_windows_loaded then
        self:_refresh()
    end
end

---@param titlePattern string # lua pattern
---@return hs.axuielement editor_window
function AppWindows:get_window_by_title_or_throw(titlePattern)
    self:_ensure_loaded()
    local win = self:_get_window_by_title_or_throw(titlePattern)
    -- crude, for now the window you want to lookup, if it is not valid anymore then try refresh cache
    if not win:isValid() then
        self:_refresh()
        win = self:_get_window_by_title_or_throw(titlePattern)
    end
    if not win then
        error("No window found matching pattern '" .. titlePattern .. "'")
    end
    return win
end

---@param titlePattern string # lua pattern
---@return hs.axuielement editor_window
function AppWindows:_get_window_by_title_or_throw(titlePattern)
    local start = GetTime()
    for title, win in pairs(self.windows_by_title) do
        if title:match(titlePattern) then
            PrintTook("getWindowByTitle took", start)
            return win
        end
    end
    PrintTook("getWindowByTitle failed", start)
    error("No ScreenPal window matching pattern '" .. titlePattern .. "' found")
end

---@return hs.axuielement editor_window
function AppWindows:editor_window_or_throw()
    return self:get_window_by_title_or_throw("^ScreenPal -")
end

-- Example usage:
-- local app = getScreenPalAppElementOrThrow()
-- local spCache = ScreenPalCache:new(app)
-- local editorWin = spCache:getEditorWindowOrThrow()
-- -- use editorWin as needed.
