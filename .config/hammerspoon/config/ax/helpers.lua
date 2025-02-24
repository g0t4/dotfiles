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
