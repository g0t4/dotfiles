local log = require("config.logs").hammerspoons()
---@class ToolBarWindow
---@field app_windows AppWindows
local ToolBarWindow = {}
ToolBarWindow.__index = ToolBarWindow

---@param app_windows AppWindows
---@return ToolBarWindow
function ToolBarWindow.new(app_windows)
    local o = setmetatable({}, ToolBarWindow)
    o.app_windows = app_windows
    return o
end

function ToolBarWindow:find_my_window()
    return self.app_windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.addedit.toolbar.menu.window-ZOrder=1(Undefined+1)")
end

---@param exact_match string
---@return hs.axuielement | nil
function ToolBarWindow:get_button_by_description(exact_match)
    return self:get_button_by_description_matching("^" .. exact_match .. "$")
end

---@param lua_pattern string
---@return hs.axuielement | nil
function ToolBarWindow:get_button_by_description_matching(lua_pattern)
    local win = self:find_my_window()
    if not win then return end

    -- -- takes <3ms to find the button, that's fine for now, let's not cache controls
    local button = win:button_by_description_matching(lua_pattern)
    if button and not button:isValid() then
        print("WARNING: Button matching pattern '" .. lua_pattern .. "' is not valid, unexpectedly... " .. hs.inspect(button))
        -- IIAC this would only happen if an OLD window was still valid that had an invalid button
        -- that does not seem likely, instead I would assume only the most recent window reference is valid
        -- ** DO NOT put this code into every element lookup, unless this happens with OK
    end
    return button
end

function ToolBarWindow:wait_for_an_open_edit_tool()
    -- PRN return edit tool type? (see notes in is_an_edit_tool_open() below)
    -- toolbar opens to cancel/ok one edit tool is opened/started
    wait_until(function() self:is_an_edit_tool_open() end, 20, 20, "edit tool is open?")
end

--- is it open right now?
---   USE "wait" to wait for it to be open
--- alias to express intention that an edit tool is open
--- (not just ok/cancel which technically could be open due to other reasons, though not AFAIK)
function ToolBarWindow:is_an_edit_tool_open()
    -- PRN return edit tool type? not sure I can reliably discern that though
    --   FYI might need to go off of color of the edit in timeline!
    return (self:get_button_by_description("Cancel") ~= nil)
        or (self:get_button_by_description("OK") ~= nil)
end

function ToolBarWindow:wait_for_tools_button()
    return wait_for_element(function() return self:get_button_by_description("Tools") end, 20, 20, "button Tools")
end

function ToolBarWindow:wait_for_tools_button_then_press_it()
    if not wait_for_element_then_press_it(function() return self:get_button_by_description("Tools") end, 20, 20) then
        error("clicking Tools button failed") -- kill action is fine b/c I will be using this in streamdeck button handlers, just means that button press dies
    end
end

function ToolBarWindow:wait_for_ok_button()
    return wait_for_element(function() return self:get_button_by_description("OK") end, 20, 20, "button OK")
end

function ToolBarWindow:wait_for_ok_button_then_press_it()
    if not wait_for_element_then_press_it(function() return self:get_button_by_description("OK") end, 20, 20) then
        error("clicking OK button failed") -- kill action is fine b/c I will be using this in streamdeck button handlers, just means that button press dies
    end
    -- FYI taking 300-400ms to find Tools button, so don't shirk waiting
    self:wait_for_tools_button()
    -- no further action, thus don't need return value (not found, no diff than if found)
end

---@return hs.axuielement[]
function ToolBarWindow:get_edits_buttons()
    self:wait_for_tools_button() -- good way to wait for toolbar to be "ready"
    -- first two are not for edits, they're the Tools menu and button to use the last used tool (Volume in this case)
    -- AXButton: desc:'Tools'
    -- AXButton: desc:'Volume'
    -- AXButton: desc:'Shape (2.68 sec)'
    -- AXButton: desc:'Volume (0.32 sec)'
    --   the buttons for current edits/tools have () in description
    --
    --   FYI in AppleScript I used:
    --       return a reference to (every button of my toolbar whose description ends with " sec)")
    --       use this if you have issues with just ()
    --
    local win = self:find_my_window()
    return vim.iter(win:buttons())
        :filter(function(button)
            local description = button:attributeValue("AXDescription")
            return string.match(description, "%b()") ~= nil
        end)
        :totable()
end

---@param substring string
---@return hs.axuielement[]
function ToolBarWindow:get_edit_buttons_by_description(substring)
    return vim.iter(self:get_edits_buttons())
        :filter(function(button) return button:attributeValue("AXDescription"):find(substring) ~= nil end)
        :totable()
end

---@return hs.axuielement[]
function ToolBarWindow:get_volume_edit_buttons()
    return self:get_edit_buttons_by_description("Volume")
end

-- * buttons for edit actions
function ToolBarWindow:get_remove_this_edit_button()
    return self:get_button_by_description_matching("^Remove this edit")
end

function ToolBarWindow:get_copy_this_edit_button()
    return self:get_button_by_description_matching("^Copy overlay")
end

function ToolBarWindow:get_preview_this_edit_button()
    return self:get_button_by_description_matching("^Preview this edit")
end

function ToolBarWindow:get_ok_accept_this_edit_button()
    return self:get_button_by_description_matching("^Accept this edit")
end

return ToolBarWindow
