local SETTINGS_PREFIX = "streamdeck_page_"

local M = {}

local function getkey(deckName, appModuleName)
    return SETTINGS_PREFIX .. deckName .. "_" .. appModuleName
end

---@param deckName string
---@param appModuleName string
---@return number
function M.getSavedPageNumber(deckName, appModuleName)
    -- TODO how expensive is this? probably not worth caching IIAC
    local settings = hs.settings.get(getkey(deckName, appModuleName))
    if settings == nil then
        return 1
    end
    return settings
end

---@param deckName string
---@param appModuleName string
---@param pageNumber number
function M.setSavedPageNumber(deckName, appModuleName, pageNumber)
    hs.settings.set(getkey(deckName, appModuleName), pageNumber)
    if M.appsObserver ~= nil then
        M.appsObserver:onPageNumberChanged(deckName, appModuleName, pageNumber)
    end
end

---@param deckName string
---@param appModuleName string
function M.clearSavedPageNumber(deckName, appModuleName)
    hs.settings.set(getkey(deckName, appModuleName), nil)
end

---@param observer AppsObserver
function M.setAppsObserver(observer)
    M.appsObserver = observer
end

return M
