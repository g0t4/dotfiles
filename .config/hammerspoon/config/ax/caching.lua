local hsax = require("hs.axuielement")

--   TODO use CacheEntry instead of any?
--
---@class CachedElement
---@field element hs.axuielement The accessibility element to wrap.
---@field cache table<string, any> A cache of attribute values.
local CachedElement = {}
CachedElement.__index = CachedElement


--- Create a new CachedElement from an AXUIElement.
---@param axElement hs.axuielement The accessibility element to wrap.
---@return CachedElement
function CachedElement.new(axElement)
    assert(axElement, "Expected an hs.axuielement")
    -- luals chokes on these assertions (TLDR it doesn't have a concept of userdata<T>... IIUC which is very strange not to)
    -- assert(axElement and type(axElement) == "userdata" and axElement["__name"] == "hs.axuielement", "Expected an hs.axuielement")
    local self = setmetatable({}, CachedElement)
    self.element = axElement
    self.cache = {}
    self.typeCache = {}
    return self
end

--- Retrieve a single attribute, using cache if available.
---@param name string The attribute name.
---@return any value The value of the attribute.
function CachedElement:attribute(name)
    -- TODO avoid double lookup on non-existent attributes
    --   PRN? add a cacheEntry type to hold nil and signal looked up already
    if not self.cache[name] then
        self.cache[name] = self.element:attributeValue(name)
    end
    return self.cache[name]
end

--- Retrieve all attributes (cached after first call).
---@return table attributes A table of attribute values.
function CachedElement:attributes()
    if not self.cache.__all then
        self.cache.__all = self.element:allAttributeValues() or {}
    end
    return self.cache.__all
end

--- Retrieve the attribute type, using cache if available.
---@param name string The attribute name.
---@return string|nil The attribute type as a string.
function CachedElement:attributeType(name)
    if not self.typeCache[name] then
        self.typeCache[name] = self.element:attributeType(name)
    end
    return self.typeCache[name]
end

--- Manually clear the cache if needed.
function CachedElement:clearCache()
    self.cache = {}
    self.typeCache = {}
end

--- Retrieve the AXUIElement.
---@return CachedElement|nil The AXUIElement.
function CachedElement.forApp(appName)
    -- FYI this already borders on getting into strategy to locate element... save that for later
    -- PRN make a throwable version?
    -- PRN take both string and hs.application
    local app = hs.application.find(appName)
    if not app then
        return nil
    end
    local appElement = hs.axuielement.applicationElement(app)
    if appElement == nil then
        print("forApp - no app element for " .. app)
        return nil
    end
    return CachedElement.new(appElement)
end

--- @return string
function CachedElement:__tostring()
    return "CachedElementz: " .. self.element:attributeValue("AXRole")
end

return CachedElement
