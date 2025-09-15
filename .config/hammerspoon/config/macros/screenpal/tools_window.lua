---@class ToolsWindow
---@field win hs.axuielement
---@field _btn_ok hs.axuielement
---@field _btn_cancel hs.axuielement
---@field _btn_tools hs.axuielement
---@field _btn_cut hs.axuielement
---@field _btn_silence_tool hs.axuielement
local ToolsWindow = {}
ToolsWindow.__index = ToolsWindow

---@param win hs.axuielement
---@return ToolsWindow
function ToolsWindow.new(win)
    local o = setmetatable({}, ToolsWindow)
    o.win = win
    o:force_refresh_cached_controls()
    return o
end

---@param element hs.axuielement
function ToolsWindow:_load_element(element)
    local description = element:axDescription()
    local role = element:axRole()

    if role == "AXButton" then
        if description == "OK" then
            self._btn_ok = element
            return
        elseif description == "Cancel" then
            self._btn_cancel = element
            return
        elseif description == "Tools" then
            self._btn_tools = element
            return
        elseif description == "Cut" then
            self._btn_cut = element
            return
        elseif description:find("Silence %(") then
            self._btn_silence_tool = element
            return
        end
    end
    -- find new controls, uncomment this:
    print(string.format("role: %s, description: %s", role, description))
end

function ToolsWindow:force_refresh_cached_controls()
    self._btn_ok = nil
    -- FYI caching is not required here ... takes 0.1ms currently to load the elements
    local start = get_time()
    vim.iter(self.win:children())
        :each(function(e) self:_load_element(e) end)
    print_took("building cache of tool window", start)
end

function ToolsWindow:is_ok_visible()
    if self._btn_ok == nil or not self._btn_ok:isValid() then
        self:force_refresh_cached_controls()
    end
    return self._btn_ok ~= nil
end

return ToolsWindow
