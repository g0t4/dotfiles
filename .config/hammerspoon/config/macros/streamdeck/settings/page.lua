local SETTINGS_PREFIX = "streamdeck_page_"

local M = {
    -- TODO remove later
    appsObserver = nil,
}

local function getkey(deckName, appNameAsSettingsKey)
    return SETTINGS_PREFIX .. deckName .. "_" .. appNameAsSettingsKey
end

---@param deckName string
---@param appNameAsSettingsKey string
---@return number
function M.getSavedPageNumber(deckName, appNameAsSettingsKey)
    local settings = hs.settings.get(getkey(deckName, appNameAsSettingsKey)) -- < 2 to 12us (microseconds)
    if settings == nil then
        return 1
    end
    return settings
end

---@param deckName string
---@param appNameAsSettingsKey string
---@param pageNumber number
function M.setSavedPageNumber(deckName, appNameAsSettingsKey, pageNumber)
    hs.settings.set(getkey(deckName, appNameAsSettingsKey), pageNumber)
    if M.appsObserver ~= nil then
        M.appsObserver:onPageNumberChanged(deckName, appNameAsSettingsKey, pageNumber)
    end
end

---@param deckName string
---@param appNameAsSettingsKey string
function M.clearSavedPageNumber(deckName, appNameAsSettingsKey)
    hs.settings.set(getkey(deckName, appNameAsSettingsKey), nil)
end

---@param observer AppsObserver
function M.setAppsObserver(observer)
    -- TODO decouple appsObserver from these settings (along w/ pushing decksController into AppObserver)
    M.appsObserver = observer
end

return M
