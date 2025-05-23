local application = require("hs.application")
local M = {}

-- TODO impement cancelation of search task(s)?
M.searchTasks = {}

---@return hs.axuielement
function GetAppElement(appName)
    local app = application.find(appName)
    local appElement = hs.axuielement.applicationElement(app)
    assert(appElement ~= nil, "could not find app element for app: " .. appName)
    return appElement
end

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
    local FcpxInspectorPanel = require("config.macros.fcpx.inspector_panel")
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

-- *** streamdeck Keyboard Maestro wrapper to catch errors and log them and rethrow for KM to show too ***
function StreamDeckKeyboardMaestroRunner(what)
    -- I want error in hammerspoon logs too
    -- I also like the notification from KM b/c that is immediately visible
    --   FYI AFAICT KM will use exit code to decide when to show for NOTIFICATIONS
    --   BUT, it seems to always show on ANY STDOUT if you choose window as the option in KM
    --   IOTW AFAICT I only wanna use notifications in KM for "output"
    -- then when I go to look into the issue I want HS logs
    --
    -- FYI w/o this its easy to think unhandled exceptions are being swallowed when its just KM not showing errors (b/c you said ignore results, rightly so b/c results all the time are annoying)... anyways use this to always log them)
    -- TODO can I just wire up something such that anyone that calls hs CLI, the errors are caught and logged... then I wouldn't need this
    --     anyone that calls hs CLI the errors will go to their CLI instance's STDOUT...
    --     thus wrap here to catch here too
    --
    -- anything printed/unhandled here is going to show in logs for hs CLI => only for KM notifications in the case of KM calling this
    xpcall(function()
        -- keep all parsing inside too so I catch those errors and show in HS logs too
        local func = load(what)
        if func == nil then
            error("failed to load: " .. what)
            return
        end
        func()
    end, function(errorMsg) print("error: ", errorMsg) end)
    -- TODO verify it still shows notification for KM?
end

-- *** ask-openai troubleshooting brave devtools randomly doesn't get selected text

---@return hs.axuielement
function GetBraveAppElement()
    return GetAppElement("com.brave.Browser.beta")
end

---@return hs.axuielement window, hs.axuielement app
function GetBraveFocusedWindowElement()
    local app = GetBraveAppElement()
    assert(app ~= nil)
    local window = app:axFocusedWindow()
    -- todo allow nil if not open?
    assert(window ~= nil)
    return window, app
end

function PrintActions(elem)
    print("ACTIONS:")
    for i, n in pairs(elem:actionNames() or {}) do
        print(n)
    end
end

function PrintAttributes(elem)
    print("ATTRIBUTES:")
    for n, v in pairs(elem) do
        print(n, hs.inspect(v))
    end
end

function SearchForDevToolsTextArea(callbackWithSelectedText)
    local focusedWindow, appElem = GetBraveFocusedWindowElement()

    -- PRN also have systemWideElement's AXFocusedUIElement... which could be a fallback too if app level ever has issues, though this one was not reliable with DevTools but still two unreliables might get 90% to reliable :)
    local appElem_FocusedUIElement = appElem:attributeValue("AXFocusedUIElement")
    -- FYI systemwide AXFocusedUIElement randomly came back nil when using DevTools...
    --   HOWEVER, I do not know if that's also true for appElem's AXFocusedUIElement!!! might just be a systemwide issue

    -- !!! bring back this primary, for now I am testing fallback mechanism
    if appElem_FocusedUIElement ~= nil then
        local selectedText = appElem_FocusedUIElement:attributeValue("AXSelectedText")
        if selectedText == nil or selectedText == "" then
            -- try AXValue (when no selection)
            selectedText = appElem_FocusedUIElement:attributeValue("AXValue")
        end
        -- PRN fallthrough if attrs return nothing (unless empty?)
        -- PrintAttributes(appElem_FocusedUIElement)
        -- FYI here are attrs from last appElem_FocusedUIElement:
        -- 2025-04-06 02:05:34: ATTRIBUTES:
        -- 2025-04-06 02:05:34: AXPosition	{ x = 27.0, y = 783.0 }
        -- 2025-04-06 02:05:34: AXSize	{ h = 32.0, w = 904.0 }
        -- 2025-04-06 02:05:34: AXColumnHeaderUIElements	nil
        -- 2025-04-06 02:05:34: AXTopLevelUIElement	<userdata 1> -- hs.axuielement: AXWindow (0x600000604038)
        -- 2025-04-06 02:05:34: AXSelectedTextRange	{ length = 0, location = 12 }
        -- 2025-04-06 02:05:34: AXLinkedUIElements	{}
        -- 2025-04-06 02:05:34: AXBlockQuoteLevel	0
        -- 2025-04-06 02:05:34: AXEditableAncestor	<userdata 1> -- hs.axuielement: AXTextArea (0x6000006194b8)
        -- 2025-04-06 02:05:34: AXOwns	nil
        -- 2025-04-06 02:05:34: AXHelp	nil
        -- 2025-04-06 02:05:34: AXWindow	<userdata 1> -- hs.axuielement: AXWindow (0x60000061b578)
        -- 2025-04-06 02:05:34: AXAccessKey	nil
        -- 2025-04-06 02:05:34: AXURL	nil
        -- 2025-04-06 02:05:34: AXDOMIdentifier	""
        -- 2025-04-06 02:05:34: AXFrame	{ h = 32.0, w = 904.0, x = 27.0, y = 783.0 }
        -- 2025-04-06 02:05:34: AXTitle	""
        -- 2025-04-06 02:05:34: AXVisited	false
        -- 2025-04-06 02:05:34: AXSelectedTextRanges	{ { length = 0, location = 12 } }
        -- 2025-04-06 02:05:34: AXFocusableAncestor	<userdata 1> -- hs.axuielement: AXTextArea (0x60000063cf78)
        -- 2025-04-06 02:05:34: AXChildren	{ <userdata 1> -- hs.axuielement: AXGroup (0x6000006213f8) }
        -- 2025-04-06 02:05:34: AXInvalid	"false"
        -- 2025-04-06 02:05:34: AXElementBusy	false
        -- 2025-04-06 02:05:34: AXTitleUIElement	nil
        -- 2025-04-06 02:05:34: AXSelected	false
        -- 2025-04-06 02:05:34: AXCustomContent	nil
        -- 2025-04-06 02:05:34: AXSelectedTextMarkerRange	<userdata 1> -- hs.axuielement.axtextmarkerrange: (0x60000062c678)
        -- 2025-04-06 02:05:34: AXParent	<userdata 1> -- hs.axuielement: AXGroup (0x60000062e638)
        -- 2025-04-06 02:05:34: AXStartTextMarker	<userdata 1> -- hs.axuielement.axtextmarker: (0x60000062edf8)
        -- 2025-04-06 02:05:34: AXValue	"how do I get id=foo"
        -- 2025-04-06 02:05:34: AXEndTextMarker	<userdata 1> -- hs.axuielement.axtextmarker: (0x60000062f138)
        -- 2025-04-06 02:05:34: AXVisibleCharacterRange	{ length = 12, location = 0 }
        -- 2025-04-06 02:05:34: AXEnabled	true
        -- 2025-04-06 02:05:34: AXSelectedText	""
        -- 2025-04-06 02:05:34: AXNumberOfCharacters	12
        -- 2025-04-06 02:05:34: AXDOMClassList	{ "cm-content", "cm-lineWrapping" }
        -- 2025-04-06 02:05:34: AXSubrole	nil
        -- 2025-04-06 02:05:34: ChromeAXNodeId	"56851335"
        -- 2025-04-06 02:05:34: AXFocused	true
        -- 2025-04-06 02:05:34: AXPlaceholderValue	nil
        -- 2025-04-06 02:05:34: AXHighestEditableAncestor	<userdata 1> -- hs.axuielement: AXTextArea (0x60000062af78)
        -- 2025-04-06 02:05:34: AXValueAutofillAvailable	false
        -- 2025-04-06 02:05:34: AXRoleDescription	"text entry area"
        -- 2025-04-06 02:05:34: AXInsertionPointLineNumber	0
        -- 2025-04-06 02:05:34: AXRole	"AXTextArea"
        -- 2025-04-06 02:05:34: AXRows	{}
        -- 2025-04-06 02:05:34: AXRequired	false
        -- 2025-04-06 02:05:34: AXDescription	"Console prompt"
        -- 2025-04-06 02:05:34: AXSelectedRows	{}
        callbackWithSelectedText(selectedText, appElem_FocusedUIElement)
        return
    end

    -- !! OK a fresh restart of brave... it falls through here with no AXFocusedUIElement
    -- !!! BUT THEN if I just open up my UI Callout Inspector and close it... then magically it finds AXFocusedUIElement
    --    also it finds AXTitle="DevTools" below in fallback which also doesn't work until inspector opened! WTF is going on!
    --  and when I inspect app level it shows AXFocusedUIElement correctly
    --    is there an enumeration issue?
    hs.alert.show("FYI no appElem AXFocusedUIElement found... open your inspector to tmp fix")

    -- AXTextArea '' - Console prompt
    -- AXHighestEditableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
    --    todo look for presence of AXHighestEditableAncestor?
    -- local criteria = { attribute = "AXDescription", value = "Console prompt" } -- took 22s! ouch
    --    TODO!  DOES THIS GO FAST WHEN IT IS FOCUSED?! or was it random luck when I did same search over in adjustBoxElement? and found this immediately (4th control tested)
    -- local criteria = { attribute = "AXRole", value = "AXTextArea" }
    -- print("searching")

    -- FYI AXWebArea('DevTools') => can find with both of these criteria:
    -- local criteria = { attribute = "AXRole", value = "AXWebArea" } -- 50 to 100ms! from focusedWindow
    local criteria = { attribute = "AXTitle", value = "DevTools" } -- same 50 to 100ms
    -- FYI can combine criteria using a func!
    FindOneElement(focusedWindow, criteria,
        function(_message, results, _numResultsAdded)
            if #results == 0 then
                -- this happens on restart brave too... before I open the UI Callout Inspector as a workaround for the above issue
                hs.alert.show("no DevTools fallback match, try open inspect tool and close it")
                return
            end
            if #results ~= 1 then
                print("FYI found " .. #results .. ", expected 1")
            end

            -- FYI this one is plenty to get selected text! and then we just type over the top!
            --  somehow the selected text attrs bubble up like 20 layers in devtools!
            local selectedText = results[1]:attributeValue("AXSelectedText")
            callbackWithSelectedText(selectedText, results[1])

            -- FYI could fallback to secondary search if narrow enough
            -- * i.e. could I quickly find a different control and navigate to DevTools input from it?
            --
            -- local criteria2 = { attribute = "AXRole", value = "AXTextArea" }
            -- FindOneElement(results[1], criteria2,
            --     function(_message, results, numResultsAdded)
            --         -- FINDING other AXTextArea's which is not surprising
            --         for i, elem in ipairs(results) do
            --             print(i .. ": ", InspectHtml(elem))
            --             PrintActions(elem)
            --             PrintAttributes(elem)
            --             -- AXEditableAncestor	<userdata 1> -- hs.axuielement: AXTextArea (0x600006278f78)
            --             -- AXHighestEditableAncestor	<userdata 1> -- hs.axuielement: AXTextArea (0x6000062780b8)
            --         end
            --         -- TODO warn if multi matches?
            --     end
            -- )
        end
    )
end

-- *** fcpx helpers

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
    -- unique ref: app:window('Final Cut Pro'):splitGroup():group():splitGroup()
end

require("config.macros.google-docs")
require("config.macros.msft_office")

return M
