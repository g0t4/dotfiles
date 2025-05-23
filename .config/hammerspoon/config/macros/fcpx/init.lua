local FcpxInspectorPanel = require("config.macros.fcpx.inspector_panel")

---@return hs.axuielement
function GetFcpxAppElement()
    -- 1.4ms for com.apple.FinalCut
    return GetAppElement("com.apple.FinalCut")
end

---@return hs.axuielement, hs.axuielement
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
---@field window hs.axuielement
---@field fcpx hs.axuielement
---@field topToolbar FcpxTopToolbar
---@field inspector FcpxInspectorPanel
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

-- * published parameters (for titles)

-- TODO center X
-- TODO center Y
-- TODO x width
-- TODO y height
-- TODO increment by 0.01 sounds like a useful feature... read box, add 0.01 ... that's the sweet spot for adjustments
--    or maybe 0.02/0.05... TBD

function StreamDeckFcpx_PublishedParams_CenterX()
    -- app:window(3):splitGroup(1):group(1):splitGroup(1):group(1):splitGroup(1):group(3):group(1):group(1):scrollArea(1)
    --   :textField(2)
    --
    -- AXDescription: center x scrubber<string>
    -- AXEnabled: true<bool>
    -- AXFocused: true<bool>
    -- AXHelp: Center X Scrubber<string>
    -- AXRoleDescription: text field<string>
    -- AXValue: -0.6<string>
    --
    local window = FcpxEditorWindow:new()
    window.inspector:showTitleInspector()
    -- TODO! FINISH THIS

    -- local window = GetFcpxEditorWindow()
    -- local sg = window:splitGroup(1):group(1):splitGroup(1)
    -- print(sg)

    -- panel w/ pub params:
    -- app:window(1):splitGroup(1):group(1):splitGroup(1):group(1):splitGroup(1):group(3)
    --
    -- AXFocused: false<bool>
    -- AXRoleDescription: group<string>
    -- AXTitleUIElement: AXGroup<hs.axuielement>
    --
    -- press 'c' to show children
    --
    -- unique ref: app:window('Final Cut Pro'):splitGroup():group():splitGroup()
end

function StreamDeckFcpxViewerToggleComments()
    -- TODO can I search in menu items for it? I didn't find in general search but menu items might have it

    local function afterSearch(_message, results, _numResultsAdded)
        local menu = results[1]
        if menu == nil then
            error("didn't find menu")
            return
        end

        menu:performAction("AXPress")
        for _, menuItem in ipairs(menu:menu(1)) do
            if menuItem:attributeValue("AXTitle") == "Show Captions" then
                menuItem:performAction("AXPress")
            end

            -- attributes when captions are turned ON:
            -- AXEnabled: true<bool> -- *** doesn't change with ON/OFF
            -- AXIdentifier: _NS:210<string>
            -- AXMenuItemCmdModifiers: 8<number>
            -- AXMenuItemMarkChar: ✓<string>   -- *** this is gone if OFF
            -- AXMenuItemPrimaryUIElement: AXMenuItem 'Show Captions' _NS:210<hs.axuielement>
            -- AXSelected: true<bool>  -- *** this doesn't change with ON/OFF
            -- AXTitle: Show Captions<string>
        end

        -- TODO menu items here might have it too?

        -- app:window(1) :splitGroup(2):group(1) :splitGroup(1):group(2) :splitGroup(1):group(3):group(1):menuButton(1)
        -- :menu(1):menuItem(37)
        -- criteria = { attribute = "AXTitle", value = "Show Captions" }
        -- FindOneElement(menu, criteria, function(_, menuButton, _)
        --     print("found: ", InspectHtml(menuButton))
        -- end)
    end

    -- app:window(2) :splitGroup(1):group(1) :splitGroup(1):group(2) :splitGroup(1):group(3):group(1):menuButton(1)
    --
    -- AXDescription: View Options Menu Button<string>
    -- AXEnabled: true<bool>
    -- AXFocused: false<bool>
    -- AXIdentifier: _NS:687<string>
    -- AXRoleDescription: menu button<string>
    -- AXTitle: View<string>
    --
    -- elementSearch: app:window(2):splitGroup(1):group(1):splitGroup(1)
    --    FYI didn't save any time using this elementSearch vs starting at window level (arguably this elementSearch though could indicate any of the above levels to boost search though so it was helpful that it pointed out window)

    local criteria = { attribute = "AXDescription", value = "View Options Menu Button" }
    -- using window shaves off 200ms! (150-190ms only now!, vs 400ms if start at app level - likely b/c of menus)
    local startSearch = GetFcpxEditorWindow()
    FindOneElement(startSearch, criteria, afterSearch)
end
