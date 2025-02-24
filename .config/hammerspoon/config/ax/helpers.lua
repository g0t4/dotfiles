local fun = require("fun")
local axuielement = require("hs.axuielement") -- load to modify its metatable

-- goal here is to simplify syntax for navigating children by roles (and index)
--    :childrenWithRole("AXWindow")[1]
--        => :window(1)
--    :childrenWithRole("AXWindow")
--        => :windows()

-- PRN allow index to be string? for title lookup like AppleScript? might want windowTitle("title") instead to avoid unecessary type checks and magic in what it matches on?

local axuielemMT = hs.getObjectMetatable("hs.axuielement")

axuielemMT.windows = function(self)
    return self:childrenWithRole("AXWindow")
end
axuielemMT.window = function(self, index)
    return self:windows()[index]
end

axuielemMT.splitGroups = function(self)
    return self:childrenWithRole("AXSplitGroup")
end
axuielemMT.splitGroup = function(self, index)
    return self:splitGroups()[index]
end

axuielemMT.groups = function(self)
    return self:childrenWithRole("AXGroup")
end
axuielemMT.group = function(self, index)
    return self:groups()[index]
end

axuielemMT.staticTexts = function(self)
    return self:childrenWithRole("AXStaticText")
end
axuielemMT.staticText = function(self, index)
    return self:staticTexts()[index]
end

-- AXCheckBox
axuielemMT.checkBoxes = function(self)
    return self:childrenWithRole("AXCheckBox")
end
axuielemMT.checkBox = function(self, index)
    return self:checkBoxes()[index]
end

-- AXTextField
axuielemMT.textFields = function(self)
    return self:childrenWithRole("AXTextField")
end
axuielemMT.textField = function(self, index)
    return self:textFields()[index]
end

-- AXTextArea
axuielemMT.textAreas = function(self)
    return self:childrenWithRole("AXTextArea")
end
axuielemMT.textArea = function(self, index)
    return self:textAreas()[index]
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
