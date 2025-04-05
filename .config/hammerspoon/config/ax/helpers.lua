local fun = require("fun")
local axuielement = require("hs.axuielement") -- load to modify its metatable
local f = require("config.helpers.underscore")
require("config.helpers.misc")

-- goal here is to simplify syntax for navigating children by roles (and index)
--    :childrenWithRole("AXWindow")[1]
--        => :window(1)
--    :childrenWithRole("AXWindow")
--        => :windows()

-- PRN allow index to be string? for title lookup like AppleScript? might want windowTitle("title") instead to avoid unecessary type checks and magic in what it matches on?

-- mark as class so I can modify w/o diagnostics noise
---@class hs.axuielement
local axuielemMT = hs.getObjectMetatable("hs.axuielement")

---@param appName string
---@return hs.axuielement
function expectAppElement(appName)
    -- *** btw "expect" implies get + assert
    local hsApp = hs.application.find(appName)
    assert(hsApp ~= nil, "axUiAppTyped: could not find app")
    local appElement = hs.axuielement.applicationElement(hsApp)
    assert(appElement ~= nil, "axUiAppTyped: could not find app element")
    return appElement
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
    local focusedWindow = self:focusedWindow()
    assert(focusedWindow ~= nil, "axUiAppTyped: could not find focused window")
    return focusedWindow
end

---@return hs.axuielement
axuielemMT.expectFocusedMainWindow = function(self)
    local focusedWindow = self:expectFocusedWindow()
    local axMain = focusedWindow:attributeValue("AXMain")
    assert(axMain == true, "axUiAppTyped: focused window is not main")
    return focusedWindow
end

---@return hs.axuielement[]
axuielemMT.windows = function(self)
    return self:childrenWithRole("AXWindow") or {}
end
---window by title returns first match, no guarantee only one match
---@param index number|string @index (number) or title (string)
---@return hs.axuielement
axuielemMT.window = function(self, index)
    if type(index) == "string" then
        local windows = self:windows()
        for _, window in ipairs(windows) do
            local title = window:title() -- or maybe try value of first staticText descendant?
            if title == index then return window end
        end
        -- easier to throw error, I can see that in hammerspoon logs easily enough then downstream doesn't have to deal with it (notably type hints and asserts)
        error("axuielemMT.window: could not find window with title " .. tostring(index))
    end
    return self:windows()[index]
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
---@param index number
---@return hs.axuielement
axuielemMT.splitGroup = function(self, index)
    return self:splitGroups()[index]
end

---@return hs.axuielement[]
axuielemMT.groups = function(self)
    return self:childrenWithRole("AXGroup") or {}
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
    return lowercaseFirstLetter(singular)
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
---@return hs.axuielement|nil
axuielemMT.axParent = function(elem)
    return elem:attributeValue("AXParent")
end

-- *** ATTRIBUTE HELPERS ***
---@param elem hs.axuielement
---@return boolean
axuielemMT.isAttributeValueUnique = function(elem, attrName)
    local elemAttrValue = elem:attributeValue(attrName)
    if elemAttrValue == nil or elemAttrValue == "" then
        -- don't try to index by ''... reality is as soon as a sibling appears it might be nil/empty too, so this is just as useles then as index
        return false
    end
    local parent = elem:axParent()
    if parent == nil then
        -- no parent, cannot know
        error("isAttributeValueUnique(" .. elem .. ", " .. attrName .. ") called on element with no parent")
        return false
    end
    -- TODO add type hints for childrenWithRole (this is hs.axuielement API right?)
    local siblings = parent:childrenWithRole(elem:axRole()) or {}
    for _, sibling in ipairs(siblings) do
        if elem ~= sibling and elemAttrValue == sibling:attributeValue(attrName) then
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
    -- title is most common, used by most elements
    if axuielemMT.isAttributeValueUnique(elem, "AXTitle") then
        -- PRN? generalize axQuoted method to take an attrName?
        -- PRN extract ref builder funcs, refIndex(), refTitle(), refDescription(), etc?
        return elem:singular() .. "(" .. axTitleQuoted(elem) .. ")"
    end
    local role = elem:axRole()
    if role == "AXWindow" then
        -- TODO? windows => allow AXSubrole => also allow index reference?
        -- fallback on index as unique ref (unique enough, I don't want to stop looking beneath the window level - if I did stop I'd never really look much past the window level and all this code would be pointless, maybe it is anwyays :) )
        return elem:singular() .. "(" .. GetElementSiblingIndex(elem) .. ")"
    end

    return nil -- == not unique
end

-- TODO move these onto axuieleemMT as extension methods
function axValueQuoted(element)
    if not element then return "" end
    local value = element:attributeValue("AXValue")
    if not value then
        return ""
    end
    if value then
        return value
    end
end

function axDescriptionQuoted(element)
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

function axTitleQuoted(element)
    if not element then return "" end

    local title = element:attributeValue("AXTitle")
    if not title then
        return ""
    end

    if title then
        return "'" .. title .. "'"
    end
end

function BuildHammerspoonLuaTo(toElement)
    local tmp = fun.enumerate(toElement:path())
        :map(function(_, pathItem)
            local singular = pathItem:singular()
            if singular == "application" then
                -- this is just meant as a generic example, not actually using as is
                -- TODO could hsow hs.application.find() too (to set app)
                return "app"
            end
            -- PRN overrides for singulars that don't match AXRole
            local siblingIndex = GetElementSiblingIndex(pathItem)
            if singular == "splitGroup" then
                -- add space before the colon to help split up deep specifiers
                --   splitGroup is often "evenly" distributed
                return " :" .. singular .. "(" .. siblingIndex .. ")"
            end
            return ":" .. singular .. "(" .. siblingIndex .. ")"
        end)
        :totable()
    -- todo split on line length too (minimal though)
    local lines = {}
    for i, s in ipairs(tmp) do
        if i > 1 and #lines[#lines] + string.len(s) < 120 then
            lines[#lines] = lines[#lines] .. s
        else
            table.insert(lines, s)
        end
    end
    return table.concat(lines, "\n  ")
end

function sortedAttributeNames(element)
    -- TODO can I make an enumerator like pairs(sortedAttributeNames(element))?
    if not element or not element.attributeNames then return {} end
    local attributes = element:attributeNames()
    table.sort(attributes)
    return attributes
end
