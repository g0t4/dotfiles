local application = require("hs.application")
local M = {}

-- TODO impement cancelation of search task(s)?
M.searchTasks = {}

function GetAppElement(appName)
    local app = application.find(appName)
    return hs.axuielement.applicationElement(app)
end

function GetFcpxAppElement()
    -- 1.4ms for com.apple.FinalCut
    return GetAppElement("com.apple.FinalCut")
end

function MacroFcpxFindXSlider()
    local function afterFindTitlePanel(message, searchTask, numResultsAdded)
        if numResultsAdded == 0 then
            print("no title panel found")
            return
        end

        -- checkbox 1 of
        --
        --   AXActivationPoint = {x=1539.0, y=54.0}
        --   AXDescription = "Title Inspector"
        --   AXEnabled = true
        --   AXFocused = false
        --   AXFrame = {x=1529.0, y=44.0, h=20.0, w=20.0}
        --   AXHelp = "Show the Title Inspector"
        --   AXIdentifier = "_NS:10"
        --   AXPosition = {x=1529.0, y=44.0}
        --   AXRole = "AXCheckBox"
        --   AXRoleDescription = "toggle button"
        --   AXSize = {h=20.0, w=20.0}
        --   AXSubrole = "AXToggle"
        --   AXTitle = "Title"

        -- if not enabled then I need to click it
        local checkbox = searchTask[1]
        if checkbox:attributeValue("AXValue") == 0 then
            print("checkbox not enabled")
            checkbox:performAction("AXPress")
            -- checkbox:setAttributeValue("AXValue", 1)
        else
            print("checkbox already enabled")
        end
    end

    local fcpx = GetFcpxAppElement()
    local criteria = { attribute = "AXDescription", value = "Title Inspector" } -- 270ms to 370ms w/ count=1
    FindOneElement(fcpx, criteria, afterFindTitlePanel)
end

function TestBack2BackElementSearch()
    EnsureClearedWebView()

    local function afterYSliderSearch(message, searchTask, numResultsAdded)
        PrintToWebView("results: ", numResultsAdded)
        DumpHtml(searchTask)
    end

    local function afterSearch(message, searchTask, numResultsAdded)
        PrintToWebView("results: ", numResultsAdded)
        DumpHtml(searchTask)

        -- SHIT I forgot I needed to nest the next search! interesting that it goes faster still...
        --   also now I can't recall if slider is neseted under title panel button... I think it's not! :)
        local ySliderCriteria = { attribute = "AXHelp", value = "Y Slider" }
        FindOneElement(GetFcpxAppElement(), ySliderCriteria, afterYSliderSearch)
    end

    -- OMG finding button to show panels is nearly instant!! I can use this as a first search (Fallback) if fixed path doesn't work!
    --     OR Can I just search every time?
    --     FYI must set count = 1 to be fast
    local criteria = { attribute = "AXDescription", value = "Title Inspector" } -- 270ms to 370ms w/ count=1

    -- slider (deeply nested)
    -- local criteria = { attribute = "AXHelp", value = "Y Slider" } -- 2.5s w/ count=1 (~10+ w/o)

    FindOneElement(GetFcpxAppElement(), criteria, afterSearch)

    -- NOTES:
    -- takes < half time if I know there's only one item I want to find!
    --   taking 5 seconds for a full search in FCPX...
    --   deosn't mean I can't search but I need to narrow my search scope (i.e. find panel I want and search there instead of globally in app!)
    --     search can be used to provide some flexibility when controls rearrange or otherwise aren't consistently in same spots
    --     IDEA => find a fixed scope (i.e. panel) and search within it (the dynamic scope)... OR...
    --        trigger search if fixed element specifier no longer works and if search works then alert use to update to new specifier!
    --        SO maybe search should be on demand so I can search when something moves? and then I would want app wide search most likely
end

function FindOneElement(app, criteria, callback)
    local startTime = GetTime()
    local criteriaFunction = hs.axuielement.searchCriteriaFunction(criteria)
    local namedModifiers = { count = 1 }


    local function afterSearch(...)
        print("time to callback: " .. GetElapsedTimeInMilliseconds(startTime) .. " ms")
        callback(...)
    end

    local searchTask = app:elementSearch(afterSearch, criteriaFunction, namedModifiers)

    -- TODO M.searchTasks[searchTask] = true
end

return M
