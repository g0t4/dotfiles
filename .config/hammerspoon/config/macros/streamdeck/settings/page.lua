local SETTINGS_PREFIX = "streamdeck_page_"

local M = {
    appsObserver = nil,
    decksController = nil,
}

local function getkey(deckName, appModuleName)
    return SETTINGS_PREFIX .. deckName .. "_" .. appModuleName
end

---@param deckName string
---@param appModuleName string
---@return number
function M.getSavedPageNumber(deckName, appModuleName)
    local settings = hs.settings.get(getkey(deckName, appModuleName)) -- < 2 to 12us (microseconds)
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
    -- TODO decouple decksController and appsObserver from these settings (along w/ pushing decksController into AppObserver)
    --    ALLOW for now to test new refactoring
    M.appsObserver = observer
    M.decksController = observer.decks
end

---@return DecksController|nil
function M.getDecksController()
    return M.decksController
end

return M
