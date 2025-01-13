local inspect = hs.inspect.inspect
local focusedHSWindow = hs.window.focusedWindow()
local focusedWinAXUIElem = hs.axuielement.windowElement(focusedHSWindow) -- HSWin => AXUIElem window (FYI .AsHSWindow can go back to HSWin)

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
end

if false then
    print('AXChildren')
    for i, v in pairs(focusedWinAXUIElem:attributeValue("AXChildren") or {}) do
        -- enumerate children elements
        print(i, v)
    end
end
