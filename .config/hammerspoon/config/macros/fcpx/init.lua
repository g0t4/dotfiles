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

---only expensive to find this the first time (remains valid across changing selections - titles,callouts,etc)
---@type hs.axuielement?
local _cached_inspector_panel_group = nil

function FcpxFindAndEnsureInspectorPanelIsOpen(checkbox_description, callback)
    -- PRN setup run_async to unravel the callback hell below (and in nested functions)

    -- FYI speed up testing by selecting an element in the Inspector Panel => takes much less time to find checkbox globally

    local fcpx = GetFcpxAppElement()
    local window = fcpx:attributeValue("AXFocusedWindow")
    local criteria = { attribute = "AXDescription", value = checkbox_description }

    local function show_respective_panel(_, searchTask, numResultsAdded)
        if numResultsAdded == 0 then
            print("no " .. checkbox_description .. "panel found")
            return
        end
        local foundCheckbox = searchTask[1]

        -- ensure title panel is visible!
        if foundCheckbox:attributeValue("AXValue") == 0 then
            foundCheckbox:performAction("AXPress")
        end

        -- FYI foundCheckbox is recreated on selection changes so don't cache it
        --   whereas grandparent appears stable (across selections)
        ---@type hs.axuielement
        _cached_inspector_panel_group = foundCheckbox:attributeValue("AXParent"):attributeValue("AXParent")
        callback(_cached_inspector_panel_group, foundCheckbox)
    end

    if _cached_inspector_panel_group and _cached_inspector_panel_group:isValid() then
        -- search again but from the cached panel (very fast @50ms) for the checkbox so I can ensure the panel is still visible!
        FindOneElement(_cached_inspector_panel_group, criteria, show_respective_panel)
        return
    end
    -- TODO can't I narrow down where I look a little bit? to speed this up
    --  main issue is if the panel isn't there b/c a clip item isn't selected to show it... it will timeout after 20 seconds
    FindOneElement(window, criteria, show_respective_panel)
end

function FcpxTitlePanelFocusOnElementByAttr(attrName, attrValue, callback)
    FcpxFindAndEnsureInspectorPanelIsOpen("Title Inspector", function(inspector_panel, title_checkbox)
        -- if static path fails here, search might work...
        local scrollarea1 = inspector_panel:attributeValue("AXChildren")[1][1][1]
        local elem = GetChildWithAttr(scrollarea1, attrName, attrValue)
        elem:setAttributeValue("AXFocused", true)
        if callback then callback(elem) end
    end)
end

function FcpxTitlePanelFocusOnElementByDescription(description, callback)
    -- FYI it is ok to just assume the control is there, it will mostly just work and when it doesn't then I can troubleshoot
    --    that is how most of my applescripts work too!
    --    LATER, PRN, I can develop automatic troubleshooting too... even when using these presumptive [1][1][2] et
    FcpxTitlePanelFocusOnElementByAttr("AXDescription", description, callback)
end

function FcpxTitlePanelChangeElemValue(delta, description)
    FcpxTitlePanelFocusOnElementByDescription(description, function(elem)
        local val = elem:axValue()
        local new_value = tonumber(val) + tonumber(delta)
        local rounded_three_decimals = string.format("%.3f", new_value)
        print(rounded_three_decimals)

        -- seems slightly faster to type the new value? both work:
        -- elem:setAttributeValue("AXValue", rounded_three_decimals)
        hs.eventtap.keyStrokes(rounded_three_decimals) -- type it in! (and it will be "read" by the app as the new value)

        -- w/o return it will not preview the changes, also needed to type over the value again next time I call this
        hs.eventtap.keyStroke({}, "return")
    end)
end

function FcpxTitlePanelFocusOnXWidth()
    FcpxTitlePanelFocusOnElementByDescription("x scrubber")
end

function FcpxTitlePanelFocusOnYHeight()
    FcpxTitlePanelFocusOnElementByDescription("y scrubber")
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

function StreamDeckToggleNoiseGate()
    print("looking for noise gate")
    -- TODO ideally check to make sure a clip is selected else this is a giant waste of time
    --    TODO if i figure that out then use similar to make sure shape is selected before trying to show X/Y center/inc/dec
    FcpxFindAndEnsureInspectorPanelIsOpen("Audio Inspector", function(inspector_panel, audio_checkbox)
        inspector_panel:dumpAttributes()
        if not audio_checkbox then
            -- if no audio checkbox, no reason to proceed (searches will block and be slow and come up with nothing)
            hs.alert.show("No Audio Inspector panel found (no checkbox)... do you have a clip selected in the timeline?")
            return
        end


        -- * search within a static located sub-panel
        -- inspector_panel s/b:
        --    app:window(1):splitGroup(1):group(1):splitGroup(1):group(2):splitGroup(1):group(4)
        -- static then down to group to search in:
        --    :group(1):splitGroup(1):group(1):group(1):scrollArea(1)
        --    TODO if this search breaks, try intermediate searches to speed up? or just fix static path or make flexible
        -- wow this is fast if I search from this subpanel (70ms even if on diff panel)
        --
        local criteria = { attribute = "AXDescription", value = "noise gate check box" }
        local static_subpanel = inspector_panel:group(1):splitGroup(1):group(1):group(1):scrollArea(1)
        FindOneElement(static_subpanel, criteria, function(_, searchTask, numResultsAdded)
            hs.alert.show("FOUND IT")
            print(numResultsAdded)
            print(searchTask)
        end)

        -- if static path fails here, search might work...
        -- local scrollarea1 = inspector_panel:attributeValue("AXChildren")[1][1][1]
        -- local elem = GetChildWithAttr(scrollarea1, attrName, attrValue)
        -- elem:setAttributeValue("AXFocused", true)
        -- if callback then callback(elem) end
    end)

    -- * Noise Gate Checkbox
    -- app:window(2):splitGroup(1):group(1):splitGroup(1):group(2):splitGroup(1):group(4):group(1):splitGroup(1):group(1)
    --   :group(1):scrollArea(1):checkBox(4)
    --
    -- AXDescription: noise gate check box<string>
    -- AXEnabled: true<bool>
    -- AXFocused: false<bool>
    -- AXHelp: Noise Gate Check Box<string>
    -- AXRoleDescription: checkbox<string>
    -- AXValue: 1<number>
    -- frame: x=1529.0,y=323.0,w=14.0,h=20.0
    --
    -- press 'c' children, 'e' everything
    --
    -- unique ref: app:window('Final Cut Pro'):splitGroup():group():splitGroup()


    -- * Noise Gate title (static text)
    -- app:window(2):splitGroup(1):group(1):splitGroup(1):group(2):splitGroup(1):group(4):group(1):splitGroup(1):group(1)
    --   :group(1):scrollArea(1):staticText(10)
    --
    -- AXEnabled: true<bool>
    -- AXFocused: false<bool>
    -- AXRoleDescription: text<string>
    -- AXValue: Noise Gate<string>
    -- frame: x=1545.0,y=320.0,w=266.0,h=26.0
    --
    -- unique ref: app:window('Final Cut Pro'):splitGroup():group():splitGroup()
    --
end
