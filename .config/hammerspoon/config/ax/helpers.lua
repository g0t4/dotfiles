local axuielement = require("hs.axuielement") -- load it

-- goal here is to simplify syntax for navigating children by roles (and index)
--    :childrenWithRole("AXWindow")[1]
--        => :windows(1)
-- PRN allow index to be string? for title lookup like AppleScript? might want windowTitle("title") instead to avoid unecessary type checks and magic in what it matches on?

local function childrenOrIndex(self, role, index)
    if index == nil then
        return self:childrenWithRole(role)
    end
    return self:childrenWithRole(role)[index]
end

local axuielemMT = hs.getObjectMetatable("hs.axuielement")
axuielemMT.windows = function(self, index)
    return childrenOrIndex(self, "AXWindow", index)
end

axuielemMT.splitGroups = function(self, index)
    return childrenOrIndex(self, "AXSplitGroup", index)
end

axuielemMT.groups = function(self, index)
    return childrenOrIndex(self, "AXGroup", index)
end

axuielemMT.staticTexts = function(self, index)
    return childrenOrIndex(self, "AXStaticText", index)
end
