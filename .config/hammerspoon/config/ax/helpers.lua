local fun = require("fun")
local axuielement = require("hs.axuielement") -- load to modify its metatable
local f = require("config.helpers.underscore")

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

axuielemMT.windows = function(self)
    return self:childrenWithRole("AXWindow")
end
---@param index number
---@return hs.axuielement
axuielemMT.window = function(self, index)
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
            local role = pathItem:attributeValue("AXRole")
            if role == "AXApplication" then
                -- this is just meant as a generic example, not actually using as is
                -- TODO could hsow hs.application.find() too (to set app)
                return "app"
            end
            local singular = role:gsub("^AX", "")
            singular = lowercaseFirstLetter(singular)
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
    return table.concat(tmp, "")
end

function sortedAttributeNames(element)
    -- TODO can I make an enumerator like pairs(sortedAttributeNames(element))?
    if not element or not element.attributeNames then return {} end
    local attributes = element:attributeNames()
    table.sort(attributes)
    return attributes
end
