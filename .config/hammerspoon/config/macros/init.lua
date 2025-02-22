local application = require("hs.application")
local M = {}

-- TODO impement cancelation of search task(s)?
M.searchTasks = {}

function MacroFcpxFindXSlider()
    EnsureClearedWebView()

    local app = application.find("com.apple.FinalCut")
    local fcpx = hs.axuielement.applicationElement(app)

    local function afterSearch(message, searchTask, numResultsAdded)
        PrintToWebView("results: ", numResultsAdded)
        DumpHtml(searchTask)
    end

    --   AXDescription = "Title Inspector"
    -- OMG finding button to show panels is nearly instant!! I can use this as a first search (Fallback) if fixed path doesn't work!
    --     OR Can I just search every time?
    --     FYI must set count = 1 to be fast
    -- local criteria = { attribute = "AXDescription", value = "Title Inspector" }

    -- slider (deeply nested)
    local criteria = { attribute = "AXHelp", value = "Y Slider" } --, -- value = "y_slider" }
    -- setTimeout doesn't seem to work for elementSearch?!

    local criteriaFunction = hs.axuielement.searchCriteriaFunction(criteria)
    -- FYI takes < half time if I know there's only one item I want to find!
    --   taking 5 seconds for a full search in FCPX...
    --   deosn't mean I can't search but I need to narrow my search scope (i.e. find panel I want and search there instead of globally in app!)
    --     search can be used to provide some flexibility when controls rearrange or otherwise aren't consistently in same spots
    --     IDEA => find a fixed scope (i.e. panel) and search within it (the dynamic scope)... OR...
    --        trigger search if fixed element specifier no longer works and if search works then alert use to update to new specifier!
    --        SO maybe search should be on demand so I can search when something moves? and then I would want app wide search most likely
    local namedModifiers = { count = 1 }
    local searchTask = fcpx:elementSearch(afterSearch, criteriaFunction, namedModifiers)
    -- TODO wire up button to cancel any outstanding search tasks
end

return M
