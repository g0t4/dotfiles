local application = require("hs.application")
function MacroFcpxFindXSlider()
    EnsureClearedWebView()

    -- local app = hs.application.frontmostApplication()
    local app = application.find("Final Cut Pro")
    local fcpx = hs.axuielement.applicationElement(app)

    -- local elementCriteria = EnumTableValues(hs.axuielement.roles)
    --     :filter(function(e) return string.find(e, "y_slider") end)
    --     :totable()
    -- print("searching")

    local function afterSearch(message, searchTask, numResultsAdded)
        PrintToWebView("results: ", numResultsAdded)
    end

    local criteriaFunction = hs.axuielement.searchCriteriaFunction({
        attribute = "AXHelp",
        value = "Y Slider",
        -- value = "y_slider",
    })
    -- FYI takes < half time if I know there's only one item I want to find!
    --   taking 5 seconds for a full search in FCPX...
    --   deosn't mean I can't search but I need to narrow my search scope (i.e. find panel I want and search there instead of globally in app!)
    --     search can be used to provide some flexibility when controls rearrange or otherwise aren't consistently in same spots
    --     IDEA => find a fixed scope (i.e. panel) and search within it (the dynamic scope)... OR...
    --        trigger search if fixed element specifier no longer works and if search works then alert use to update to new specifier!
    --        SO maybe search should be on demand so I can search when something moves? and then I would want app wide search most likely
    local namedModifiers = { count = 1 }
    local searchTask = fcpx:elementSearch(afterSearch, criteriaFunction, namedModifiers)
end
