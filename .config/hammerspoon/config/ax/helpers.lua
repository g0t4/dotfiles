local f = require("config.helpers.underscore")
local timer = require("hs.timer")
require("config.helpers.misc")
require("config.helpers.perf")

-- goal here is to simplify syntax for navigating children by roles (and index)
--    :childrenWithRole("AXWindow")[1]
--        => :window(1)
--    :childrenWithRole("AXWindow")
--        => :windows()

-- PRN allow index to be string? for title lookup like AppleScript? might want windowTitle("title") instead to avoid unecessary type checks and magic in what it matches on?

local axuielement = hs.axuielement -- must include otherwise cannot extend its metatable
-- mark as class so I can modify w/o diagnostics noise
---@class hs.axuielement
local axuielemMT = hs.getObjectMetatable("hs.axuielement")

---@param app_name string
---@return hs.axuielement
function get_app_element_or_throw(app_name)
    -- TODO disable warning about hs.application.enableSpotlightForNameSearches
    local hs_app = hs.application.find(app_name)
    assert(hs_app ~= nil, "axUiAppTyped: could not find app: " .. app_name)
    local app_element = hs.axuielement.applicationElement(hs_app)
    assert(app_element ~= nil, "axUiAppTyped: could not find app element: " .. app_name)
    return app_element
end

axuielemMT.dumpActions = function(self)
    f.each(self:actionNames() or {}, function(index, name)
        print(name, self:actionDescription(name))
    end)
end

-- FYI THIS IS NOT TESTED
axuielemMT.axPress = function(self)
    -- I added this function w/o having a test case yet
    --   turned out the control I wanted to click doesn't work with press action so I couldn't test this
    --   I wanted to leave this design for a future use case though
    self:performAction("AXPress")
end

axuielemMT.dumpAttributes = function(self)
    f.each(self:allAttributeValues() or {}, function(name, value)
        print(name, hs.inspect(value))
    end)
end

---@return hs.axuielement|nil
axuielemMT.focusedWindow = function(self)
    return self:attributeValue("AXFocusedWindow")
end

---@return hs.axuielement
axuielemMT.expectFocusedWindow = function(self)
    local focused_window = self:focusedWindow()
    assert(focused_window ~= nil, "axUiAppTyped: could not find focused window")
    return focused_window
end

---@return hs.axuielement
axuielemMT.expectFocusedMainWindow = function(self)
    local focused_window = self:expectFocusedWindow()
    local ax_main = focused_window:attributeValue("AXMain")
    assert(ax_main == true, "axUiAppTyped: focused window is not main")
    return focused_window
end

---@return hs.axuielement[]
axuielemMT.windows = function(self)
    return self:childrenWithRole("AXWindow") or {}
end
---@param index number
---@return hs.axuielement
function axuielemMT:window(index)
    return self:windows()[index]
end
--- Returns FIRST with matching title, NOT ALL!
---@param title string
---@return hs.axuielement
function axuielemMT:window_by_title(title)
    local windows = self:windows()
    for _, window in ipairs(windows) do
        local window_title = window:axTitle()
        if window_title == title then return window end
    end
    error("axuielemMT.window_by_title: could not find window with title " .. tostring(title))
end

---@return hs.axuielement[]
axuielemMT.tabGroups = function(self)
    return self:childrenWithRole("AXTabGroup") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.tabGroup = function(self, index)
    return self:tabGroups()[index]
end

---@return hs.axuielement[]
axuielemMT.buttons = function(self)
    return self:childrenWithRole("AXButton") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.button = function(self, index)
    return self:buttons()[index]
end
--- Returns FIRST with matching description, NOT ALL!
---@param desc string
---@return hs.axuielement
function axuielemMT.button_by_description(self, desc)
    return vim.iter(self:buttons())
        :find(function(button)
            return button:axDescription() == desc
        end)
end
--- Returns FIRST with matching identifier, NOT ALL!
---@param identifier string
---@return hs.axuielement
function axuielemMT.button_with_identifier(self, identifier)
    return vim.iter(self:buttons())
        :find(function(button)
            return button:axIdentifier() == identifier
        end)
end


---@return hs.axuielement[]
axuielemMT.radioButtons = function(self)
    return self:childrenWithRole("AXRadioButton") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.radioButton = function(self, index)
    return self:radioButtons()[index]
end


---@param index number
---@return hs.axuielement
axuielemMT.standardWindow = function(self, index)
    -- FYI only add standardWindows() if the need arises
    --
    -- and I prefer this approach for picking one by index b/c it should be more efficient
    local windows = self:windows()
    for i = 1, #windows do
        local window = windows[i]
        if window:attributeValue("AXSubrole") == "AXStandardWindow" then
            return window
        end
    end
    return nil
end

---@return hs.axuielement[]
axuielemMT.splitGroups = function(self)
    return self:childrenWithRole("AXSplitGroup") or {}
end
--- Returns FIRST with matching description, NOT ALL!
---@param desc string
---@return hs.axuielement
axuielemMT.splitGroup_by_description = function(self, desc)
    return vim.iter(self:splitGroups())
        :find(function(group)
            return group:axDescription() == desc
        end)
end
---@param index number
---@return hs.axuielement
axuielemMT.splitGroup = function(self, index)
    return self:splitGroups()[index]
end


---@return hs.axuielement[]
axuielemMT.groups = function(self)
    return self:childrenWithRole("AXGroup") or {}
end
---Returns FIRST with matching description, NOT ALL!
---@param desc string
---@return hs.axuielement
axuielemMT.group_by_description = function(self, desc)
    return vim.iter(self:groups())
        :find(function(group)
            return group:axDescription() == desc
        end)
end
---@param index number
---@return hs.axuielement
axuielemMT.group = function(self, index)
    return self:groups()[index]
end

---@return hs.axuielement[]
axuielemMT.staticTexts = function(self)
    return self:childrenWithRole("AXStaticText") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.staticText = function(self, index)
    return self:staticTexts()[index]
end

---@return hs.axuielement[]
axuielemMT.checkBoxes = function(self)
    return self:childrenWithRole("AXCheckBox") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.checkBox = function(self, index)
    return self:checkBoxes()[index]
end

---@return hs.axuielement[]
axuielemMT.textFields = function(self)
    return self:childrenWithRole("AXTextField") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.textField = function(self, index)
    return self:textFields()[index]
end

---@return hs.axuielement[]
axuielemMT.textAreas = function(self)
    return self:childrenWithRole("AXTextArea") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.textArea = function(self, index)
    return self:textAreas()[index]
end

---@return hs.axuielement[]
axuielemMT.menus = function(self)
    return self:childrenWithRole("AXMenu") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.menu = function(self, index)
    return self:menus()[index]
end

---@return hs.axuielement[]
axuielemMT.menuButtons = function(self)
    return self:childrenWithRole("AXMenuButton") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.menuButton = function(self, index)
    return self:menuButtons()[index]
end

---AXMenuItem
---@return hs.axuielement[]
axuielemMT.menuItems = function(self)
    return self:childrenWithRole("AXMenuItem") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.menuItem = function(self, index)
    return self:menuItems()[index]
end

---@return hs.axuielement[]
axuielemMT.toolbars = function(self)
    return self:childrenWithRole("AXToolbar") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.toolbar = function(self, index)
    return self:toolbars()[index]
end

---@return hs.axuielement[]
axuielemMT.children = function(self)
    return self:attributeValue("AXChildren") or {}
end

---@return hs.axuielement[]
axuielemMT.scrollAreas = function(self)
    return self:childrenWithRole("AXScrollArea") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.scrollArea = function(self, index)
    return self:scrollAreas()[index]
end

---@return hs.axuielement[]
axuielemMT.scrollBars = function(self)
    return self:childrenWithRole("AXScrollBar") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.scrollBar = function(self, index)
    return self:scrollBars()[index]
end

---@return hs.axuielement[]
axuielemMT.tables = function(self)
    return self:childrenWithRole("AXTable") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.table = function(self, index)
    return self:tables()[index]
end

---@return hs.axuielement[]
axuielemMT.rows = function(self)
    return self:childrenWithRole("AXRow") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.row = function(self, index)
    return self:rows()[index]
end

---@return hs.axuielement[]
axuielemMT.cells = function(self)
    return self:childrenWithRole("AXCell") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.cell = function(self, index)
    return self:cells()[index]
end

--- layout areas
---@return hs.axuielement[]
axuielemMT.layoutAreas = function(self)
    return self:childrenWithRole("AXLayoutArea") or {}
end
---@param index number
---@return hs.axuielement
axuielemMT.layoutArea = function(self, index)
    return self:layoutAreas()[index]
end

--- first child that matches predicate
---@param predicate fun(element: hs.axuielement): boolean
---@return hs.axuielement|nil
axuielemMT.firstChild = function(self, predicate)
    local children = self:children()
    for _, child in pairs(children) do
        if predicate(child) then
            return child
        end
    end
end

---@param element hs.axuielement
---@return string|nil
axuielemMT.singular = function(element)
    ---@type string|nil
    local role = element:attributeValue("AXRole")
    if not role then
        return nil
    end
    local singular = role:gsub("^AX", "")
    return lowercase_first_letter(singular)
end

-- *** ATTRIBUTE ACCESSOR EXTENSION METHODS ***
--- FYI purpose is to provide strongly typed API that also replaces nil with "" as is reasonable
---@param elem hs.axuielement
---@return string
axuielemMT.axTitle = function(elem)
    return elem:attributeValue("AXTitle") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axDescription = function(elem)
    return elem:attributeValue("AXDescription") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axValue = function(elem)
    return elem:attributeValue("AXValue") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axMaxValue = function(elem)
    return elem:attributeValue("AXMaxValue") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axMinValue = function(elem)
    return elem:attributeValue("AXMinValue") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axRole = function(elem)
    return elem:attributeValue("AXRole") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axRoleDescription = function(elem)
    return elem:attributeValue("AXRoleDescription") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axHelp = function(elem)
    return elem:attributeValue("AXHelp") or ""
end
---@param elem hs.axuielement
---@return string
axuielemMT.axIdentifier = function(elem)
    return elem:attributeValue("AXIdentifier") or ""
end

---@param elem hs.axuielement
---@return hs.axuielement|nil
axuielemMT.axParent = function(elem)
    return elem:attributeValue("AXParent")
end
---@param elem hs.axuielement
---@return string|nil
axuielemMT.axSubrole = function(elem)
    return elem:attributeValue("AXSubrole") or ""
end
-- AXFocusedWindow
---@param elem hs.axuielement
---@return hs.axuielement|nil
axuielemMT.axFocusedWindow = function(elem)
    return elem:attributeValue("AXFocusedWindow")
end

-- type aliases for attributes
---@alias AXFrame { x:number, y:number, w:number, h:number }
---   this one is specific to frames, and I hope to use it to convey the type is not just CGRect but that it represents a frame
---@alias CGSize { w:number, h:number }
---@alias CFRange { location: number, length: number }
---@alias CGPoint { x:number, y:number }
-- based on: https://developer.apple.com/documentation/applicationservices/axvaluetype

---@param elem hs.axuielement
---@return AXFrame
axuielemMT.axFrame = function(elem)
    local raw_frame = elem:attributeValue("AXFrame")
    if not raw_frame then return nil end
    ---@cast raw_frame table|nil @ { x=number, y=number, w=number, h=number }
    assert(raw_frame.x and type(raw_frame.x) == "number" and raw_frame.y and type(raw_frame.y) == "number")
    assert(raw_frame.w and type(raw_frame.w) == "number" and raw_frame.h and type(raw_frame.h) == "number")
    return raw_frame
end

---@param elem hs.axuielement
---@return { x:number, y:number }
axuielemMT.axPosition = function(elem)
    local raw_pos = elem:attributeValue("AXPosition")
    if not raw_pos then return nil end
    assert(raw_pos.x and type(raw_pos.x) == "number" and raw_pos.y and type(raw_pos.y) == "number")
    return raw_pos
end
-- AXSize
---@param elem hs.axuielement
---@return { w:number, h:number }
axuielemMT.axSize = function(elem)
    local raw_size = elem:attributeValue("AXSize")
    if not raw_size then return nil end
    assert(raw_size.w and type(raw_size.w) == "number" and raw_size.h and type(raw_size.h) == "number")
    return raw_size
end

-- *** ATTRIBUTE HELPERS ***
---can you uniquely refer to this element with the value of the given attrName
---even if its value is nil or empty "", that qualifies (consumers can handle that otherwise)
---@param elem hs.axuielement
---@return boolean
axuielemMT.isAttributeValueUnique = function(elem, attr_name)
    local elem_attr_value = elem:attributeValue(attr_name)
    local parent = elem:axParent()
    if parent == nil then
        -- no parent, cannot know
        error("isAttributeValueUnique(" .. elem .. ", " .. attr_name .. ") called on element with no parent")
        return false
    end
    -- TODO add type hints for childrenWithRole (this is hs.axuielement API right?)
    local siblings = parent:childrenWithRole(elem:axRole()) or {}
    for _, sibling in ipairs(siblings) do
        if elem ~= sibling and elem_attr_value == sibling:attributeValue(attr_name) then
            -- matched a sibling
            return false
        end
    end
    -- no matches
    return true
end

---returns nil if not unique way to refer to the element
---@param elem hs.axuielement
---@return string|nil @ lua function call to one of my axuielemMT extension methods
axuielemMT.findUniqueReference = function(elem)
    -- * non-empty, unique title
    local is_title_value_unique = axuielemMT.isAttributeValueUnique(elem, "AXTitle")
    local title = elem:axTitle()
    if title and is_title_value_unique then
        return elem:singular() .. "(" .. quote(title) .. ")"
    end

    -- * non-empty, unique subrole
    local is_subrole_value_unique = axuielemMT.isAttributeValueUnique(elem, "AXSubrole")
    local sub_role = elem:attributeValue("AXSubrole")
    if is_subrole_value_unique and sub_role then
        -- add subrole= to make clear I need an arg or overload for that
        return elem:singular() .. "(subrole=" .. quote(sub_role) .. ")"
    end

    -- * non-empty, unique description
    local is_descrption_unique = axuielemMT.isAttributeValueUnique(elem, "AXDescription")
    local description = elem:attributeValue("AXDescription") or ""
    if is_descrption_unique and description then
        return elem:singular() .. "(desc=" .. quote(description) .. ")"
    end

    -- ? AXHelp, AXValue

    -- * now, allow unique and empty/nil values
    if is_title_value_unique then
        return elem:singular() .. "(" .. quote(title) .. ")"
    elseif is_subrole_value_unique and sub_role then
        return elem:singular() .. "(subrole=" .. quote(sub_role) .. ")"
    elseif is_descrption_unique and description then
        return elem:singular() .. "(desc=" .. quote(description) .. ")"
    end

    local role = elem:axRole()
    if role == "AXWindow" then
        -- fallback on index as unique ref (unique enough, I don't want to stop looking beneath the window level - if I did stop I'd never really look much past the window level and all this code would be pointless, maybe it is anwyays :) )
        return elem:singular() .. "(" .. get_element_sibling_index(elem) .. ")"
    end

    return nil -- == not unique
end

-- TODO move these onto axuielemMT as extension methods
function ax_value_quoted(element)
    if not element then return "" end
    local value = element:attributeValue("AXValue")
    if not value then
        return ""
    end
    if value then
        return value
    end
end

function ax_description_quoted(element)
    if not element then return "" end
    local description = element:attributeValue("AXDescription")
    if not description then
        return ""
    end
    if description then
        -- PRN use " if ' present?
        return "'" .. description .. "'"
    end
end

function ax_title_quoted(element)
    if not element then return "" end

    local title = element:attributeValue("AXTitle")
    if not title then
        return ""
    end

    if title then
        return "'" .. title .. "'"
    end
end

function BuildHammerspoonLuaTo(to_element)
    local ref_chain = f.imap(to_element:path(),
        function(path_item)
            local singular = path_item:singular()
            if singular == "application" then
                return "app"
            end
            local sibling_index = get_element_sibling_index(path_item) or "nil"
            return ":" .. singular .. "(" .. sibling_index .. ")"
        end)

    return ConcatIntoLines(ref_chain)
end

function ConcatIntoLines(ref_chain, max_line_length, line_continuation)
    max_line_length = max_line_length or 120
    local join_with = (line_continuation or "") .. "\n  "

    local lines = { "" }
    for _, ref in ipairs(ref_chain) do
        if #lines[#lines] + string.len(ref) < max_line_length then
            lines[#lines] = lines[#lines] .. ref
        else
            table.insert(lines, ref)
        end
    end
    return table.concat(lines, join_with)
end

function sorted_attribute_names(element)
    -- TODO can I make an enumerator like pairs(sorted_attribute_names(element))?
    if not element or not element.attributeNames then return {} end
    local attributes = element:attributeNames()
    table.sort(attributes)
    return attributes
end

function FindOneElement(app, criteria, callback)
    local start_time = get_time()
    if type(criteria) ~= "function" then
        criteria = hs.axuielement.searchCriteriaFunction(criteria)
    end
    local named_modifiers = { count = 1 }

    local function after_search(...)
        print("time to callback: " .. get_elapsed_time_in_milliseconds(start_time) .. " ms")
        callback(...)
    end

    app:elementSearch(after_search, criteria, named_modifiers)
end

local application = require("hs.application")
---@return hs.axuielement
function GetAppElement(app_name)
    local app = application.find(app_name)
    local app_element = hs.axuielement.applicationElement(app)
    assert(app_element ~= nil, "could not find app element for app: " .. app_name)
    return app_element
end

function GetChildWithAttr(parent, attr_name, attr_value)
    for _, child in ipairs(parent) do
        if child:attributeValue(attr_name) == attr_value then
            return child
        end
    end
    return nil
end

-- * helpers to wait until, click if exists, etc... like I use in AppleScript
-- idea is simple: try right away (no fat delays)... and keep trying for a while until you find it
--   that way you can have the fastest possible response w/o brittle delays
--   timeout after fixed # cycles so not going on forever
--   if smth is buggy, fix it... don't try to shrink wait interval
--   set wait interval on max amount of time to expect for the app UI to catch up

---@param search_func fun(): hs.axuielement?
---@param interval_ms number
---@param max_cycles number
---@param name string? - optional name for logging
---@return hs.axuielement?
function wait_for_element(search_func, interval_ms, max_cycles, name)
    -- TODO rewrite with syncify
    interval_ms = interval_ms or 20
    max_cycles = max_cycles or 30

    local start = get_time()
    local cycles = 0
    while cycles < max_cycles do
        local element = search_func()
        if element then
            print_took("wait_for_element " .. tostring(name), start)
            return element
        end
        timer.usleep(interval_ms * 1000)
        cycles = cycles + 1
    end

    print_took("wait_for_element " .. tostring(name) .. " timed out after " .. tostring(max_cycles) .. " cycles @ " .. tostring(interval_ms) .. "ms intervals")
    return nil
end

---@param search_func fun(): hs.axuielement?
---@param interval_ms? number
---@param max_cycles? number
---@return boolean
function wait_for_element_then_press_it(search_func, interval_ms, max_cycles)
    -- PRN extract generic wait_for_element_then_perform_action(..., action_name)
    local elem = wait_for_element(search_func, interval_ms, max_cycles)
    if elem then
        local success, err = elem:performAction("AXPress")
        print("AXPress result: " .. hs.inspect(success) .. ", err: " .. hs.inspect(err)) -- PRN add to log file! and check for success to be true (or it will be the error) or the error will be nil! - I think I was wrong about this being an
        if not success then
            -- FINALLY a central spot to log this, I keep forgetting to check this when I try to use actions!
            print("failed to AXPress elem", elem, err)
            return false
        end
        return true
    end
    print("did not find element to press")
    return false
end
