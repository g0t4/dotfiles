local fun = require("fun")
local axuielement = require("hs.axuielement") -- load to modify its metatable

-- goal here is to simplify syntax for navigating children by roles (and index)
--    :childrenWithRole("AXWindow")[1]
--        => :window(1)
--    :childrenWithRole("AXWindow")
--        => :windows()

-- PRN allow index to be string? for title lookup like AppleScript? might want windowTitle("title") instead to avoid unecessary type checks and magic in what it matches on?

-- mark as class so I can modify w/o diagnostics noise
---@class hs.axuielement
local axuielemMT = hs.getObjectMetatable("hs.axuielement")

axuielemMT.windows = function(self)
    return self:childrenWithRole("AXWindow")
end
---@param index number
---@return hs.axuielement
axuielemMT.window = function(self, index)
    return self:windows()[index]
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
