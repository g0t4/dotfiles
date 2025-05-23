-- TODO! move all config for FCPX streamdeck macros and other automations here)

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
