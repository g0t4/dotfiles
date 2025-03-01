local hsapp = require("hs.application")

---@param name string
---@return hs.application?
local function findApp(name)
    return hsapp.get(name)
end

-- tl check test.tl # fails obviously
findApp(1)
return findApp
