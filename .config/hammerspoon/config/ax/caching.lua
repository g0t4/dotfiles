local hsax = require("hs.axuielement")

--- TODO can I use hs.axuielement as type, does that help?
--- TODO can I use table<string,any>
--- TODO use CacheEntry instead of any?
---@class CachedElement
---@field element hs.axuielement
---@field cache table<string, any>
local CachedElement = {}
CachedElement.__index = CachedElement

---@param element hs.axuielement
---@return CachedElement
function CachedElement.new(element)
    assert(element, "Expected an hs.axuielement")
    -- TODO assert:
    -- luals chokes on these assertions (TLDR it doesn't have a concept of userdata<T>... IIUC which is very strange not to)
    -- assert(axElement and type(axElement) == "userdata" and axElement["__name"] == "hs.axuielement", "Expected an hs.axuielement")

    local self = setmetatable({}, CachedElement)
    self.element = element
    self.cache = {}
    self.typeCache = {}
    return self
end

--- Retrieve a single attribute, using cache if available.
---@param name string
---@return any @attribute value
function CachedElement:attribute(name)
    -- TODO avoid double lookup on non-existent attributes
    --   PRN? add a cacheEntry type to hold nil and signal looked up already
    if not self.cache[name] then
        self.cache[name] = self.element:attributeValue(name)
    end
    return self.cache[name]
end

--- Retrieve all attributes (cached after first call).
---@return table attributes
function CachedElement:attributes()
    if not self.cache.__all then
        self.cache.__all = self.element:allAttributeValues() or {}
    end
    return self.cache.__all
end

--- Retrieve the attribute type, using cache if available.
---@param name string
---@return string|nil
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
---@return CachedElement|nil
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

---@return string
function CachedElement:__tostring()
    return "CachedElementz: " .. self.element:attributeValue("AXRole")
end

return CachedElement
