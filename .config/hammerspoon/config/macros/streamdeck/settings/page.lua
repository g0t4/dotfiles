local SETTINGS_PREFIX = "streamdeck_page_"

local M = {
    -- TODO remove later
    appsObserver = nil,
}

local function getkey(deckName, appTitle)
    print("appTitle", appTitle)
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
    if M.appsObserver ~= nil then
        M.appsObserver:onPageNumberChanged(deckName, appTitle, pageNumber)
    end
end

---@param deckName string
---@param appTitle string
function M.clearSavedPageNumber(deckName, appTitle)
    hs.settings.set(getkey(deckName, appTitle), nil)
end

---@param observer AppsObserver
function M.setAppsObserver(observer)
    -- TODO decouple appsObserver from these settings (along w/ pushing decksController into AppObserver)
    M.appsObserver = observer
end

return M
