-- *** DONT FORGET to use Accessibility Inspector (superior version of UIElement Inspector b/c shows neigbhoring elements)


-- *** CONSTANTS: (static lists, IIUC from extracted from header files):
-- print('actions reference', hs.axuielement.actions) -- static list
-- print('attributes reference', hs.axuielement.attributes) -- static list, useful to explore what might be possible (when supported)
-- print('orientations reference', hs.axuielement.orientations) -- static list (horizontal, vertical, unknown)
-- print('parameterizedAttributes: ', hs.axuielement.parameterizedAttributes)
--
-- print('roles:', hs.axuielement.roles)
-- hrm... AXBrowser, AXHelpTag, AXLink, AXSystemWide?, AXUnknown
--
-- print('subroles:', hs.axuielement.subroles)
-- hrm... AXApplicationDockItem, AXProcessSwitcherList,
--          - CAN I ALTER AXProcessSwitcherList? tab switcher?!
--        AXFloatingWindow, AXSystemFloatingWindow
--        AXTextLink, AXTimeline, AXUnknown
--
-- print('rulerMarkers:', hs.axuielement.rulerMarkers)
-- print('sortDirections:', hs.axuielement.sortDirections)
-- print('units', hs.axuielement.units)


if false then
    local focusedHSWindow = hs.window.focusedWindow()
    local focusedWinAXUIElem = hs.axuielement.windowElement(focusedHSWindow) -- HSWin => AXUIElem window (FYI .AsHSWindow can go back to HSWin)

    print('Attributes')
    for k, v in pairs(focusedWinAXUIElem) do
        -- syntactic sugar for ipairs(obj:attributeNames())
        -- FYI if value is nil, it won't be included in the loop... need to directly use attributeValue... to get check that it is nil if for whatever reason that is needed
        print(k, v)
        -- ?? text related attrs (maybe useful to search elements?):
        --    AXAnnotation, AXColumnTitles, AXCustom, AXDescription, AXFilename, AXHelp, AXHeader, AXIdentifier
        --    AXLabelValue/AXLabelUIElements, AXLink, AXURL, AXListItemPrefix, AXPlaceholderValue, AXReplacementString
        --    AXRole, AXRoleDescription, AXMarkerTypeDescription, AXMarkerValues, AXServesAsTitleForUIElements
        --    AXText, AXTitle[UIElement], AXUNitDescription/AXUnits, AXValue[Description]
        --    AXVerticalUnitDescription, AXVisibleText, AXWarningValue
        -- state: AXEnabled, AXFocused, AXHidden, AXSelected
        -- FYI focus related:
        --    AXFocused, AXFocusedApplication, AXFocusedUIElement, AXFocusedWindow
    end

    print('AXChildren')
    for i, v in pairs(focusedWinAXUIElem:attributeValue("AXChildren") or {}) do
        -- enumerate children elements
        print(i, v)
    end
end

-- local pptHsApp = hs.application.find("PowerPoint")
-- dump("pptHsApp", pptHsApp)
-- local pptAxAppElem = hs.axuielement.applicationElement(pptHsApp)
-- dump("pptAxAppElem", pptAxAppElem)


-- -- ***! hs.axuielement.systemElementAtPosition(x, y | pointTable)
-- local elementAt = hs.axuielement.systemElementAtPosition(0, 0)

if false then
    -- *** system wide info (focused element/app!)
    dump(hs.axuielement.systemWideElement())
    -- HAS:
    -- 2025-01-13 03:20:44: AXFocusedApplication	hs.axuielement: AXApplication (0x6000023b1778)
    -- 2025-01-13 03:20:44: AXFocusedUIElement	hs.axuielement: AXTextArea (0x6000023b1638)
    -- 2025-01-13 03:20:44: AXRole	AXSystemWide
    -- 2025-01-13 03:20:44: AXRoleDescription
    local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    dump('focused', focused)
end

if false then
    -- *** menu items
    -- activate Writing Tools => Compose... (demonstrate menu item use)
    local app = hs.application("Script Debugger")
    app:activate()
    local item = app:findMenuItem("Compose...")
    dump("item", hs.inspect(item)) -- item is a table, not an hs.axuielementObject
    app:selectMenuItem("Compose...")
end

-- *** TODOs
-- TODO! hs.axuielement:elementSearch(callback, [criteria], [namedModifiers]) -> elementSearchObject
--    read all of: https://www.hammerspoon.org/docs/hs.axuielement.html#elementSearch
-- TODO hs.axuielement:allDescendantElements(callback, [withParents]) -> elementSearchObject
-- TODO hs.axuielement:buildTree(callback, [depth], [withParents]) -> elementSearchObject
-- immediate children:
--    hs.axuielement:childrenWithRole(role) -> table
-- hs.axuielement:elementAtPosition(x, y | pointTable) -> axuielementObject | nil, errString
--
-- hs.axuielement:setAttributeValue(attribute, value) -> axuielementObject | nil, errString
--
-- hs.axuielement:isValid() -> boolean | nil, errString
--    find out if element is removed, etc (aka invalid)
-- hs.axuielement:matchesCriteria(criteria) -> boolean
--    test like if searching?
-- hs.axuielement:path() -> table
--   OMG use with element at position!
--   THEN... I should be able to programatically produce applescript or otherwise to find an object using my own locator code...
--       I could even traverse nearby elements and find where decision points are and find differing aspects to build the unique path to object
--
--
--
