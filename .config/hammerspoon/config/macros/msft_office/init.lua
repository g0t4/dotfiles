--
-- *** OFFICE RIBBON HELPERS ***

---@return hs.axuielement
function MicrosoftOfficeGetRibbon(appName)
    local app = get_app_element_or_throw(appName)
    local window = app:expectFocusedMainWindow()

    local ribbonTabGroup = window:tabGroup(1)
    if ribbonTabGroup:attributeValue("AXDescription") ~= "ribbon" then
        print("tab group name is not 'ribbon'... will proceed anyways, just heads up if there is a problem")
    end
    return ribbonTabGroup
end

---@appName string
---@tabName string
---@return hs.axuielement ribbon
function MicrosoftOfficeEnsureTabSelected(appName, tabName)
    local ribbon = MicrosoftOfficeGetRibbon(appName)

    -- ribbon's AXValueDescription has current tab's name
    local isAlreadyOpen = ribbon:attributeValue("AXValueDescription") == tabName
    if isAlreadyOpen then
        print("tab already open: " .. tabName)

        local ribbonIsCollapsed = ribbon:attributeValue("AXValue") == nil
        if ribbonIsCollapsed then
            print("tab group is collapsed, clicking to expand")
            ribbon:performAction("AXPress")
        end

        -- PRN can add "toggle" parameter to this func and then fall through in that case?
        return ribbon
    end

    -- PRN use AXTabs to enumerate just tab children elements? (instead of radio buttons?)
    local tabButton = ribbon:firstChild(function(element)
        return element:attributeValue("AXTitle") == tabName
    end)
    assert(tabButton ~= nil, "Could not find " .. appName .. " ribbon's tab button for: " .. tabName)
    tabButton:performAction("AXPress")
    return ribbon
end

function MicrosoftOfficeClickTabButtonByTitle(appName, tabName, buttonTitle)
    local ribbon = MicrosoftOfficeEnsureTabSelected(appName, tabName)

    local criteria = { attribute = "AXTitle", value = buttonTitle }
    FindOneElement(ribbon, criteria, function(_, searchTask, numResultsAdded)
        -- WOW, 150ms to callback! much faster than manual search (which is also brittle)
        if numResultsAdded == 0 then
            print("no button found with title: " .. quote(buttonTitle))
            return
        end
        local found = searchTask[1]
        print("found button with title: " .. quote(buttonTitle))

        found:performAction("AXPress")
    end)
end

-- *** END OFFICE RIBBON HELPERS ***


require("config.macros.msft_office.excel")
require("config.macros.msft_office.pptx")
