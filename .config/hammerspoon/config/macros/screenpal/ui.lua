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
    -- FTR refresh takes 5-11ms (not terrible) so its not a huge time savings except maybe when aggregated with other savings
    local start = GetTime()
    -- print("REFRESH")
    local windows = self.app:windows()
    local new_cache = {}
    for _, win in ipairs(windows) do
        local title = win:axTitle()
        new_cache[title] = win
        -- print("  title: " .. tostring(title))
    end
    self.windows_by_title = new_cache
    print_took("  refresh took", start)
end

function AppWindows:_ensure_loaded()
    local any_windows_loaded = #self.windows_by_title == 0
    if any_windows_loaded then
        self:_refresh()
    end
end

---@param titlePattern string # lua pattern
---@return hs.axuielement editor_window
function AppWindows:get_window_by_title(titlePattern)
    self:_ensure_loaded()
    local win = self:_get_window_by_title(titlePattern)
    -- crude, for now the window you want to lookup, if it is not valid anymore then try refresh cache
    if not win or not win:isValid() then
        -- one attempt to refresh if not found or invalid
        -- rare to ask for non-existant window, so it's fine as a fallback (s/b rare to hit)
        self:_refresh()
        win = self:_get_window_by_title(titlePattern)
    end
    return win
end

---@param titlePattern string # lua pattern
---@return hs.axuielement editor_window
function AppWindows:_get_window_by_title(titlePattern)
    local start = GetTime()
    for title, win in pairs(self.windows_by_title) do
        -- print("  title: " .. tostring(title))
        if title:match(titlePattern) then
            print_took("  getWindowByTitle took", start)
            return win
        end
    end
    print_took("  getWindowByTitle failed", start)
end

---@return hs.axuielement editor_window
function AppWindows:editor_window_or_throw()
    local win = self:get_window_by_title("^ScreenPal -")
    if win then return win end
    error("No Screenpal editor window found")
end

---@return hs.axuielement editor_window
function AppWindows:get_playhead_window_or_throw()
    -- app:window(2)
    -- AXFocused: false<bool>
    -- AXMain: false<bool>
    -- AXMinimized: false<bool>
    -- AXModal: false<bool>
    -- AXRoleDescription: window<string>
    -- AXSections: [1: SectionUniqueID: AXContent, SectionObject: hs.axuielement: AXTextField (0x60000ac6b1f8), SectionDescription: Content]
    -- AXTitle: SOM-FloatingWindow-Type=edit2.posbar-ZOrder=1(Undefined+1)<string>
    local win = self:get_window_by_title("^SOM%-FloatingWindow%-Type=edit2.posbar%-ZOrder=1")
    -- if not present, should I try once to load? like what if windows list cached before it was ever visible?
    if win then return win end
    error("No playhead window found")
end

-- Example usage:
-- local app = getScreenPalAppElementOrThrow()
-- local spCache = ScreenPalCache:new(app)
-- local editorWin = spCache:getEditorWindowOrThrow()
-- -- use editorWin as needed.
