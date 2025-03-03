local SETTINGS_PREFIX = "streamdeck_page_"

local M = {}

local function getkey(deckName, appTitle)
    local appModuleName = AppModuleName(appTitle)
    return SETTINGS_PREFIX .. deckName .. "_" .. appModuleName
end

---@param deckName string
---@param appTitle string # App Name/Title
---@return number
function M.getSavedPageNumber(deckName, appTitle)
    local settings = hs.settings.get(getkey(deckName, appTitle)) -- < 2 to 12us (microseconds)
    if settings == nil then
        return 1
    end
    return settings
end

---@param deckName string
---@param appTitle string
---@param pageNumber number
function M.setSavedPageNumber(deckName, appTitle, pageNumber)
    hs.settings.set(getkey(deckName, appTitle), pageNumber)
end

---@param deckName string
---@param appTitle string
function M.clearSavedPageNumber(deckName, appTitle)
    hs.settings.set(getkey(deckName, appTitle), nil)
end

return M
