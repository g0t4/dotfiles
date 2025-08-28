local f = require("config.helpers.underscore")
require("config.helpers.misc")

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

---@param appName string
---@return hs.axuielement
function getAppElementOrThrow(appName)
    -- TODO disable warning about hs.application.enableSpotlightForNameSearches
    local hsApp = hs.application.find(appName)
    assert(hsApp ~= nil, "axUiAppTyped: could not find app: " .. appName)
    local appElement = hs.axuielement.applicationElement(hsApp)
    assert(appElement ~= nil, "axUiAppTyped: could not find app element: " .. appName)
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
-- AXFrame
---@param elem hs.axuielement
---@return table|nil @ { x=number, y=number, w=number, h=number }
axuielemMT.axFrame = function(elem)
    local rawFrame = elem:attributeValue("AXFrame")
    if not rawFrame then return nil end
    ---@cast rawFrame table|nil @ { x=number, y=number, w=number, h=number }
    assert(rawFrame.x and type(rawFrame.x) == "number" and rawFrame.y and type(rawFrame.y) == "number")
    assert(rawFrame.w and type(rawFrame.w) == "number" and rawFrame.h and type(rawFrame.h) == "number")
    return rawFrame
end
-- AXPosition
---@param elem hs.axuielement
---@return table|nil @ { x=number, y=number }
axuielemMT.axPosition = function(elem)
    local rawPos = elem:attributeValue("AXPosition")
    if not rawPos then return nil end
    assert(rawPos.x and type(rawPos.x) == "number" and rawPos.y and type(rawPos.y) == "number")
    return rawPos
end
-- AXSize
---@param elem hs.axuielement
---@return table|nil @ { w=number, h=number }
axuielemMT.axSize = function(elem)
    local rawSize = elem:attributeValue("AXSize")
    if not rawSize then return nil end
    assert(rawSize.w and type(rawSize.w) == "number" and rawSize.h and type(rawSize.h) == "number")
    return rawSize
end

-- *** ATTRIBUTE HELPERS ***
---can you uniquely refer to this element with the value of the given attrName
---even if its value is nil or empty "", that qualifies (consumers can handle that otherwise)
---@param elem hs.axuielement
---@return boolean
axuielemMT.isAttributeValueUnique = function(elem, attrName)
    local elemAttrValue = elem:attributeValue(attrName)
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
    -- * non-empty, unique title
    local isTitleValueUnique = axuielemMT.isAttributeValueUnique(elem, "AXTitle")
    local title = elem:axTitle()
    if title and isTitleValueUnique then
        return elem:singular() .. "(" .. quote(title) .. ")"
    end

    -- * non-empty, unique subrole
    local isSubroleValueUnique = axuielemMT.isAttributeValueUnique(elem, "AXSubrole")
    local subRole = elem:attributeValue("AXSubrole")
    if isSubroleValueUnique and subRole then
        -- add subrole= to make clear I need an arg or overload for that
        return elem:singular() .. "(subrole=" .. quote(subRole) .. ")"
    end

    -- * non-empty, unique description
    local isDescrptionUnique = axuielemMT.isAttributeValueUnique(elem, "AXDescription")
    local description = elem:attributeValue("AXDescription") or ""
    if isDescrptionUnique and description then
        return elem:singular() .. "(desc=" .. quote(description) .. ")"
    end

    -- ? AXHelp, AXValue

    -- * now, allow unique and empty/nil values
    if isTitleValueUnique then
        return elem:singular() .. "(" .. quote(title) .. ")"
    elseif isSubroleValueUnique and subRole then
        return elem:singular() .. "(subrole=" .. quote(subRole) .. ")"
    elseif isDescrptionUnique and description then
        return elem:singular() .. "(desc=" .. quote(description) .. ")"
    end

    local role = elem:axRole()
    if role == "AXWindow" then
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
    local refChain = f.imap(toElement:path(),
        function(pathItem)
            local singular = pathItem:singular()
            if singular == "application" then
                return "app"
            end
            local siblingIndex = GetElementSiblingIndex(pathItem) or "nil"
            return ":" .. singular .. "(" .. siblingIndex .. ")"
        end)

    return ConcatIntoLines(refChain)
end

function ConcatIntoLines(refChain, maxLineLength, lineContinuation)
    maxLineLength = maxLineLength or 120
    local joinWith = (lineContinuation or "") .. "\n  "

    local lines = { "" }
    for _, ref in ipairs(refChain) do
        if #lines[#lines] + string.len(ref) < maxLineLength then
            lines[#lines] = lines[#lines] .. ref
        else
            table.insert(lines, ref)
        end
    end
    return table.concat(lines, joinWith)
end

function sortedAttributeNames(element)
    -- TODO can I make an enumerator like pairs(sortedAttributeNames(element))?
    if not element or not element.attributeNames then return {} end
    local attributes = element:attributeNames()
    table.sort(attributes)
    return attributes
end

function FindOneElement(app, criteria, callback)
    local startTime = GetTime()
    if type(criteria) ~= "function" then
        criteria = hs.axuielement.searchCriteriaFunction(criteria)
    end
    local namedModifiers = { count = 1 }

    local function afterSearch(...)
        print("time to callback: " .. GetElapsedTimeInMilliseconds(startTime) .. " ms")
        callback(...)
    end

    app:elementSearch(afterSearch, criteria, namedModifiers)
end

local application = require("hs.application")
---@return hs.axuielement
function GetAppElement(appName)
    local app = application.find(appName)
    local appElement = hs.axuielement.applicationElement(app)
    assert(appElement ~= nil, "could not find app element for app: " .. appName)
    return appElement
end

function GetChildWithAttr(parent, attrName, attrValue)
    for _, child in ipairs(parent) do
        if child:attributeValue(attrName) == attrValue then
            return child
        end
    end
    return nil
end
