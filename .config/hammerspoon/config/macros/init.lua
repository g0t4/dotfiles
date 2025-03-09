local application = require("hs.application")
local M = {}

-- TODO impement cancelation of search task(s)?
M.searchTasks = {}

local function EnsureCheckboxIsChecked(checkbox)
    if checkbox:attributeValue("AXValue") ~= 0 then
        return
    end
    checkbox:performAction("AXPress")
    if checkbox:attributeValue("AXValue") ~= 1 then
        -- FYI errors look really nice when using hs -c "command" in terminal
        --   AND look good in notifications from Keyboard Maestro when that hs command fails
        --   Line nubmer shows in initial part of message so I can just use that to jump to spot
        --   TODO use error() in more places, basically for failed assertions
        error("checkbox was not checked")
    end
end

local function EnsureCheckboxIsUnchecked(checkbox)
    if checkbox:attributeValue("AXValue") ~= 0 then
        return
    end
    checkbox:performAction("AXPress")
    if checkbox:attributeValue("AXValue") ~= 0 then
        error("checkbox was not unchecked")
    end
end

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
    assert(fcpx, "GetFcpxEditorWindow: could not find Final Cut Pro")
    if fcpx:attributeValue("AXTitle") ~= APPS.FinalCutPro then
        print("GetFcpxEditorWindow: unexpected title", fcpx:attributeValue("AXTitle"))
        return nil
    end

    -- IIRC this is from the main window (not app) element:
    -- AXMain = true
    -- AXMinimized = false
    -- AXModal = false
    -- AXRole = "AXWindow"
    -- AXRoleDescription = "standard window"
    -- AXSections = {1={SectionDescription="Toolbar", SectionUniqueID="AXToolbar", SectionObject= (AXToolbar)}, 2={SectionDescription="Content", SectionUniqueID="AXContent", SectionObject= (AXScrollArea)}, 3={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 4={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 5={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 6={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 7={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 8={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 9={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 10={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 11={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 12={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 13={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 14={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 15={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}, 16={SectionUniqueID="AXContainer", SectionObject= (AXGroup)}}
    --   TODO AXSections are AXSections reusable entry points? in predictable order? ... that would rock if I could find panels using that, I bet I can
    -- AXSize = {h=1080.0, w=1920.0}
    -- AXSubrole = "AXStandardWindow"
    -- AXTitle = "Final Cut Pro"

    return fcpx:attributeValue("AXFocusedWindow"), fcpx
end

---@class FcpxEditorWindow
FcpxEditorWindow = {}
FcpxEditorWindow.__index = FcpxEditorWindow

function FcpxEditorWindow:new()
    local o = {}
    setmetatable(o, self)
    o.window, o.fcpx = GetFcpxEditorWindow()
    o.topToolbar = FcpxTopToolbar:new(o.window:childrenWithRole("AXToolbar")[1])
    -- everything below top toolbar
    -- use _ to signal that it's not guaranteed to be there
    o._mainSplitGroup = o.window:childrenWithRole("AXSplitGroup")[1]
    print("main split group", hs.inspect(o._mainSplitGroup))
    o.inspector = FcpxInspectorPanel:new(o)
    return o
end

function FcpxEditorWindow:rightSidePanel()
    -- FYI if overhead in lookup on every use, can memoize this... but not until I have proof its an issue.. and probabaly only for situations where 10ms is a problem
    -- FOR NOW... defer everything beyond the window!
    -- TODO this group is varying...  CAN I query smth like # elements and find what I want that way?
    return self._mainSplitGroup:group(2)
end

function FcpxEditorWindow:rightSidePanelTopBar()
    -- TODO this group is varying...
    return self:rightSidePanel():group(2)
end

function FcpxEditorWindow:leftSideEverythingElse()
    -- TODO use and rename this... b/c its not a left side panel, it's the rest of the UI (browser,timeline,events viewer,titles,generators,etc) - everything except the inspector (in my current layout)
    -- TODO this group is varying...
    return self._mainSplitGroup:group(1)
end

---@class FcpxTopToolbar
FcpxTopToolbar = {}
FcpxTopToolbar.__index = FcpxTopToolbar
function FcpxTopToolbar:new(topToolbarElement)
    local o = {}
    setmetatable(o, self)
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

---@class FcpxInspectorPanel
FcpxInspectorPanel = {}
FcpxInspectorPanel.__index = FcpxInspectorPanel
function FcpxInspectorPanel:new(window)
    local o = {}
    setmetatable(o, self)
    -- yeah at this point, probably all I can guarantee is that a window exists...
    --   panels need to be opened before any interactions, so defer all of that!
    --   FYI... I will find the right balance for where logic belongs as I use this (window vs this class, etc)
    o.window = window
    return o
end

function FcpxInspectorPanel:ensureOpen()
    -- TODO... can also use menu to show it, from CommandPost:
    -- menuBar:selectMenu({"Window", "Show in Workspace", "Inspector"})
    -- https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L261

    EnsureCheckboxIsChecked(self.window.topToolbar.btnInspector)
end

function FcpxInspectorPanel:ensureClosed()
    EnsureCheckboxIsUnchecked(self.window.topToolbar.btnInspector)
end

function FcpxInspectorPanel:topBarCheckboxByDescription(matchDescription)
    local startTime = GetTime()

    local candidates = self.window:rightSidePanel():group(2):checkBoxes()
    -- OUCH 11ms! ... IIUC b/c its cloning axuielements using CopyAttributeValue("AXChildren") every time!
    print("candidates: ", hs.inspect(candidates))
    print("time to index cbox: " .. GetElapsedTimeInMilliseconds(startTime) .. " ms")

    for _, candidate in ipairs(candidates) do
        if candidate:attributeValue("AXDescription") == matchDescription then
            print("time to found cbox: " .. GetElapsedTimeInMilliseconds(startTime) .. " ms")
            print("found fixed path to title panel checkbox")
            return candidate
        end
    end

    print("time to search failed: " .. GetElapsedTimeInMilliseconds(startTime) .. " ms")
    error("Could not find checkbox for description: " .. matchDescription)
end

function FcpxInspectorPanel:titleCheckbox()
    -- FIXED PATH CURRENTLY (this seems to have changed, extra splitgroup.. if so lets try search to find it going forward, nested under right panel which s/b mostly fixed in place)
    --
    -- longer path I found a few times:
    --    PRN recapture this using hammerspoon lua specifier...
    --    set Title to checkbox 1 of group 2 of group 5 of splitter group 1 of group 2 of ¬
    --      splitter group 1 of group 1 of splitter group 1 of window "Final Cut Pro" of ¬
    --        application process "Final Cut Pro"
    -- attrs:
    --   AXActivationPoint = {y=55.0, x=1537.0}
    --   AXDescription = "Title Inspector"
    --   AXEnabled = true
    --   AXFocused = false
    --   AXFrame = {y=44.0, h=20.0, w=20.0, x=1527.0}
    --   AXHelp = "Show the Title Inspector"
    --   AXIdentifier = "_NS:10"
    --   AXPosition = {y=44.0, x=1527.0}
    --   AXRole = "AXCheckBox"
    --   AXRoleDescription = "toggle button"
    --   AXSize = {w=20.0, h=20.0}
    --   AXSubrole = "AXToggle"
    --   AXTitle = "Title"
    --   AXValue = 1

    return self:topBarCheckboxByDescription("Title Inspector")

    -- btw CommandPost goes off of AXTitle:
    --   https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L359
    --   ALSO, uses localized (IIUC) strings to find the title match: FFInspectorTabMotionEffectTitle
end

function FcpxInspectorPanel:titleCheckboxSearch()
    FindOneElement(self.window:rightSidePanel(),
        { attribute = "AXDescription", value = "Title Inspector" },
        function(_, searchTask, numResultsAdded)
            if numResultsAdded == 0 then
                error("Could not find title inspector checkbox")
            end
            return searchTask[1]
        end)
end

function FcpxInspectorPanel:showTitleInspector()
    self:ensureOpen()
    EnsureCheckboxIsChecked(self:titleCheckbox())
    -- self:titleCheckboxSearch() -- test timing only
end

-- function StreamDeckFcpxInspectorTitlePanelEnsureClosed()
--     not using
--     local window = FcpxEditorWindow:new()
--     window.inspector:ensureClosed()
-- end

function StreamDeckFcpxInspectorTitlePanelEnsureOpen()
    local window = FcpxEditorWindow:new()
    window.inspector:showTitleInspector()
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

    local criteria = { attribute = "AXDescription", value = "Title Inspector" } -- 270ms to 370ms w/ count=1
    FindOneElement(fcpx, criteria, function(_, searchTask, numResultsAdded)
        if numResultsAdded == 0 then
            print("no title panel found")
            return
        end
        local foundCheckbox = searchTask[1]

        -- ensure title panel is visible!
        if foundCheckbox:attributeValue("AXValue") == 0 then
            foundCheckbox:performAction("AXPress")
        end

        doWithTitlePanel(foundCheckbox)
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

    local function afterYSliderSearch(_, searchTask, numResultsAdded)
        PrintToWebView("results: ", numResultsAdded)
        DumpHtml(searchTask)
    end

    local function afterSearch(_, searchTask, numResultsAdded)
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

    app:elementSearch(afterSearch, criteriaFunction, namedModifiers)
end

-- *** excel helpers

function StreamDeckPowerPointEnsureTabOpen(tabName)
    MicrosoftOfficeEnsureTabSelected("Microsoft PowerPoint", tabName)
end

function StreamDeckExcelEnsureTabOpen(tabName)
    MicrosoftOfficeEnsureTabSelected("Microsoft Excel", tabName)
end

---@return hs.axuielement
function MicrosoftOfficeGetRibbon(appName)
    local app = expectAppElement(appName)
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

function StreamDeckExcelDataTabClickSortButton()
    -- NOTES for sort button:
    -- app:window(1):tabGroup(1):scrollArea(1):group(4):button(3)
    -- scrollArea(1) is only scroll area

    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Sort")
end

function StreamDeckExcelDataTabClickReapplyButton()
    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Reapply")
end

function StreamDeckExcelDataTabClickFilterButton()
    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Filter")
end

function StreamDeckExcelDataTabClickClearButton()
    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Clear")
end

-- !!! FYI CLICK INTO CELL (toedit it) and you can get a ref to it usin my inspector OR UI Element Inspector
--    this was for 3rd column of row 5... COORDINATES IN VISIBLE SHEET CELLS ONLY (not overall)
--    app:window(1) :splitGroup(1):layoutArea(1):layoutArea(1):table(2):row(5):cell(3):group(1):textArea(1)
function StreamDeckExcelTestCellAccess()
    local app = expectAppElement("Microsoft Excel")
    local currentSheet = app:window(1):splitGroup(1):layoutArea(1):layoutArea(1):table(2)
    -- :row(5):cell(3):group(1):textArea(1)
    local function row(rowNum)
        return currentSheet:row(rowNum)
    end
    local function cell(rowNum, colNum)
        return row(rowNum):cell(colNum)
    end
    local function cellGroup(rowNum, colNum)
        return cell(rowNum, colNum):group(1)
    end
    local function cellTextArea(rowNum, colNum)
        return cellGroup(rowNum, colNum):textArea(1)
    end
    local function cellText(rowNum, colNum)
        return cellTextArea(rowNum, colNum):attributeValue("AXValue") or ""
    end
    -- TODO idea... click that fucking filter tiny ass button on top of column of current selected cell!

    print("cell text: ", cellText(5, 3))
end

-- *** end excel helpers

return M
