function MacroFcpxFindXSlider()
    EnsureClearedWebView()

    local app = hs.application.frontmostApplication()
    -- DumpHtml(app)
    local appElement = hs.axuielement.applicationElement(app)

    local elementCriteria = EnumTableValues(hs.axuielement.roles)
        :filter(function(e) return string.find(e, "Menu") end)
        :totable()

    local function afterSearch(message, searchTask, numResultsAdded)
        PrintToWebView("results: ", InspectHtml(searchTask))
    end

    local criteriaFunction = hs.axuielement.searchCriteriaFunction(elementCriteria)
    local searchTask = appElement:elementSearch(afterSearch, criteriaFunction)
end
