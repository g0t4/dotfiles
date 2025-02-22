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

function GetFcpxEditorWindow()
    local fcpx = GetFcpxAppElement()

    -- identified by:
    -- AXMain = true
    -- AXMinimized = false
    -- AXModal = false
    -- AXRole = "AXWindow"
    -- AXRoleDescription = "standard window"
    -- AXSections = {1={SectionDescription="Toolbar", SectionUniqueID="AXToolbar", SectionObject= (AXToolbar)}, 2={SectionDescription="Content", SectionUniqueID="AXContent", SectionObject= (AXScrollArea)}, 3={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 4={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 5={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 6={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 7={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 8={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 9={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 10={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 11={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 12={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 13={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 14={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 15={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 16={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}}
    --   TODO AXSections are what?
    -- AXSize = {h=1080.0, w=1920.0}
    -- AXSubrole = "AXStandardWindow"
    -- AXTitle = "Final Cut Pro"
    if fcpx:attributeValue("AXTitle") ~= "Final Cut Pro" then
        print("GetFcpxEditorWindow: unexpected title", fcpx:attributeValue("AXTitle"))
        return nil
    end

    return fcpx:attributeValue("AXFocusedWindow")
end

FcpxEditorWindow = {}
function FcpxEditorWindow:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.window = GetFcpxEditorWindow()
    o.topToolbar = FcpxTopToolbar:new(o.window:childrenWithRole("AXToolbar")[1])
    -- everything below top toolbar
    -- use _ to signal that it's not guaranteed to be there
    o._mainSplitGroup = o.window:childrenWithRole("AXSplitGroup")[1]
    local rightSidePanel = o._mainSplitGroup:childrenWithRole("AXGroup")[1]
    -- local leftSidePanel = mainSplitGroup:childrenWithRole("AXGroup")[2]
    o.inspector = FcpxInspectorPanel:new(rightSidePanel, o)
    return o
end

FcpxTopToolbar = {}
function FcpxTopToolbar:new(topToolbarElement)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.topToolbarElement = topToolbarElement
    -- TODO consider a toggle for troubleshooting... that will check more carefully (i.e. for desc here)... but not when toggle is off, like an assertion (enabled in dev, disabled in prod)
    local checkboxes = o.topToolbarElement:childrenWithRole("AXCheckBox")
    o.btnInspector = checkboxes[5]
    o.btnBrowser = checkboxes[3]
    o.btnTimeline = checkboxes[4]
    -- PRN use :matchCriteria w/ AXDescription instead of index?
    --    TODO time the difference
    --    FYI for tooggling a panel... it's perfectly fine to be slower (i.e. even 10ms is NBD)...
    --    VERSUS, siturations where I might repeat a key to change a slider in which case then speed is critical
    --
    -- o.btnBrowser = o.topToolbarElement:childrenWithRole("AXCheckBox")[3]
    -- o.btnTimeline = o.topToolbarElement:childrenWithRole("AXCheckBox")[4]
    --
    -- toolbar 1	AXToolbar		toolbar 1 of
    --     button 1	AXButton	desc="Import media from a device, camera, or archive"	button 1 of
    --     checkbox 1	AXCheckBox	desc="Show or hide the Keyword Editor"	checkbox 1 of
    --     checkbox 2	AXCheckBox		checkbox 2 of
    --     group 1	AXGroup		group 1 of
    --     checkbox 3	AXCheckBox	desc="Show or hide the Browser"	checkbox 3 of
    --     checkbox 4	AXCheckBox	desc="Show or hide the Timeline"	checkbox 4 of
    --     checkbox 5	AXCheckBox	desc="Show or hide the Inspector"	checkbox 5 of
    --     button 2	AXButton	desc="Share the project, event clip, or Timeline range"	button 2 of

    return o
end

FcpxInspectorPanel = {}
function FcpxInspectorPanel:new(panelElement, window)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.panelElement = panelElement
    o.window = window
    return o
end

function FcpxInspectorPanel:ensureOpen()
    local button = self.window.topToolbar.btnInspector
    if button:attributeValue("AXValue") == 0 then
        print("opening title inspector")
        button:performAction("AXPress")
        return
    end
    print("title inspector already open")
end

function FcpxInspectorPanel:ensureClosed()
    local button = self.window.topToolbar.btnInspector
    if button:attributeValue("AXValue") == 1 then
        print("closing title inspector")
        button:performAction("AXPress")
        return
    end
    print("title inspector already closed")
end

function FcpxInspectorPanel:showTitleInspector()
    self:ensureOpen()
end

function StreamDeckFcpxInspectorTitlePanelEnsureClosed()
    local window = FcpxEditorWindow:new()
    window.inspector:ensureClosed()
end

function StreamDeckFcpxInspectorTitlePanelEnsureOpen()
    local window = FcpxEditorWindow:new()
    window.inspector:showTitleInspector()
end

function GetFcpxRightSideInspectorPanel()
    -- FYI this panel might be somewhere else depending on layout...
    --   not sure if that would affect the element specifier, my guess is yes...
    --   thus, name it according to function so I can build upon it and then if it moves element speicifer
    --     then I can just update this one func
    local window = GetFcpxEditorWindow()
    if not window then
        error("Could not find fcpx editor window")
        return
    end
    local toolbar = window:childrenWithRole("AXToolbar")[1]
    print("toolbar", hs.inspect(toolbar))
    return mainSplitGroup
end

function FcpxFindTitlePanelCheckbox(doWithTitlePanel)
    local fcpx = GetFcpxAppElement()
    local window = fcpx:attributeValue("AXFocusedWindow")
    local checkbox = window:childrenWithRole("AXSplitGroup")[1]:childrenWithRole("AXGroup")[1]:childrenWithRole("AXSplitGroup")[1]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXSplitGroup")[1]
        :childrenWithRole("AXGroup")[5]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXCheckBox")[1]
    if checkbox ~= nil and checkbox:attributeValue("AXDescription") == "Title Inspector" then
        print("found fixed path to title panel checkbox")

        -- ensure title panel is visible!
        if checkbox:attributeValue("AXValue") == 0 then
            checkbox:performAction("AXPress")
        end

        doWithTitlePanel(checkbox)
        return
    end
    print("[WARNING] no fixed path to title panel checkbox found, falling back to search which is going to be slower, fix the fixed path to speed things up!")

    -- FIXED PATH CURRENTLY:
    --    set Title to checkbox 1 of group 2 of group 5 of splitter group 1 of group 2 of ¬
    --      splitter group 1 of group 1 of splitter group 1 of window "Final Cut Pro" of ¬
    --        application process "Final Cut Pro"
    -- attrs:
    --   AXActivationPoint = {y=54.0, x=1539.0}
    --   AXDescription = "Title Inspector"
    --   AXEnabled = true
    --   AXFocused = false
    --   AXFrame = {y=44.0, x=1529.0, w=20.0, h=20.0}
    --   AXHelp = "Show the Title Inspector"
    --   AXIdentifier = "_NS:10"
    --   AXPosition = {y=44.0, x=1529.0}
    --   AXRole = "AXCheckBox"
    --   AXRoleDescription = "toggle button"
    --   AXSize = {w=20.0, h=20.0}
    --   AXSubrole = "AXToggle"
    --   AXTitle = "Title"
    --   AXValue = 1

    local criteria = { attribute = "AXDescription", value = "Title Inspector" } -- 270ms to 370ms w/ count=1
    FindOneElement(fcpx, criteria, function(_, searchTask, numResultsAdded)
        if numResultsAdded == 0 then
            print("no title panel found")
            return
        end
        local checkbox = searchTask[1]

        -- ensure title panel is visible!
        if checkbox:attributeValue("AXValue") == 0 then
            checkbox:performAction("AXPress")
        end

        doWithTitlePanel(checkbox)
    end)
end

function GetChildWithAttr(parent, attrName, attrValue)
    for _, child in ipairs(parent) do
        if child:attributeValue(attrName) == attrValue then
            return child
        end
    end
    return nil
end

function FcpxTitlePanelFocusOnElementByAttr(attrName, attrValue)
    FcpxFindTitlePanelCheckbox(function(checkbox)
        local grandparent = checkbox:attributeValue("AXParent"):attributeValue("AXParent")
        local scrollarea1 = grandparent:attributeValue("AXChildren")[1][1][1]
        GetChildWithAttr(scrollarea1, attrName, attrValue):setAttributeValue("AXFocused", true)
    end)
end

function FcpxTitlePanelFocusOnElementByDescription(description)
    -- FYI it is ok to just assume the control is there, it will mostly just work and when it doesn't then I can troubleshoot
    --    that is how most of my applescripts work too!
    --    LATER, PRN, I can develop automatic troubleshooting too... even when using these presumptive [1][1][2] et
    FcpxTitlePanelFocusOnElementByAttr("AXDescription", description)
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
