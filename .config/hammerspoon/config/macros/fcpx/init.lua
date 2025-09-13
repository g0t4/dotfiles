local FcpxEditorWindow = require("config.macros.fcpx.editor_window")

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

-- function StreamDeckFcpxInspectorTitlePanelEnsureClosed()
--     not using
--     local window = FcpxEditorWindow:new()
--     window.inspector:ensureClosed()
-- end

function StreamDeckFcpxInspectorTitlePanelEnsureOpen()
    local window = FcpxEditorWindow:new()
    window.inspector:showTitleInspector()
end

---@type hs.axuielement?
local _cached_title_panel_checkbox = nil

function FcpxFindTitlePanelCheckbox(doWithTitlePanel)
    -- print("cached: " .. hs.inspect(_cached_title_panel_checkbox))
    -- FYI caching only works for duration of the current selected callout
    --   I think that might be useful enough to leave this as-is
    --   When you select a diff callout or smth else in timeline, the cached item here is invalid then
    --     control is likely recreated
    --  PRN could I build a dynamic path in memory instead of caching the item? and use that as a static path? instead of caching the element
    --    might be able to find a parent control that is stable enough for a search even after selecting smth else and coming back
    if _cached_title_panel_checkbox and _cached_title_panel_checkbox:isValid() then
        doWithTitlePanel(_cached_title_panel_checkbox)
        return
    end
    -- PRN setup run_async to unravel the callback hell below (and in nested functions)
    local fcpx = GetFcpxAppElement()
    local window = fcpx:attributeValue("AXFocusedWindow")
    local criteria = { attribute = "AXDescription", value = "Title Inspector" } -- 270ms to 370ms w/ count=1
    -- FYI search can be slow on first run (2s).. but then it's 100-200ms on subsequent runs so that is FAST!
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

        _cached_title_panel_checkbox = foundCheckbox
        doWithTitlePanel(foundCheckbox)
    end)
end

function FcpxTitlePanelFocusOnElementByAttr(attrName, attrValue)
    FcpxFindTitlePanelCheckbox(function(checkbox)
        -- if static path fails here, search might work!
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
    ensure_cleared_web_view()

    local function afterYSliderSearch(_, searchTask, numResultsAdded)
        print_to_web_view("results: ", numResultsAdded)
        dump_html(searchTask)
    end

    local function afterSearch(_, searchTask, numResultsAdded)
        print_to_web_view("results: ", numResultsAdded)
        dump_html(searchTask)

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
        --     print("found: ", inspect_html(menuButton))
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
