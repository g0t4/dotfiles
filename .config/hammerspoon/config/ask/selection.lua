local M = {}

function M.getSelectedText()
    -- NOTES:
    --   selected text does not work in iTerm (at least not in nvim)... that'sfine as I am not using this at all in iterm... if I was I could just impl smth specific to iterm most likley...
    --   verified works in: Brave devtools, Script Debugger and Editor, (AXValue in iterm + nvim)

    -- Access the currently focused UI element
    -- ~ 6 to 10ms first call (sometimes <1ms too)
    --   then <1ms on back to back calls
    --   max was 25ms one time... still less than 30ms just to select text with keystroke!!!
    -- COOL dont even need to specify the app! just finds frontmost app's focused element!
    local focusedElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    -- FYI this comes back nil for devtools, not sure why but when I added back Emojis spoon and restarted hs => it worked again... after which I took out Emojis spoon and it kept working?

    local app = hs.application.frontmostApplication()

    if focusedElement then
        local selectedText = focusedElement:attributeValue("AXSelectedText") -- < 0.4ms !!

        if selectedText and selectedText ~= "" then
            -- print("selected text found")
            return selectedText
        else
            local value = focusedElement:attributeValue("AXValue") -- < 0.4ms !!
            local name = app:name()
            if name == APPS.BraveBrowserBeta or name == APPS.Excel then
                -- clear the text to simulate cut behavior (clear until response starts)
                -- could select all to simulate having copied it (so response replaces it too)
                -- excel assume no selection == replace all too
                focusedElement:setAttributeValue("AXValue", "") -- TODO not working in excel
                -- TODO why is setting AXValue empty causing menu to open in dev tools?
                -- FOR NOW allow just use cmd+a in Brave too (stops the context menu from showing... odd)
                -- if name == APPS.MicrosoftExcel then
                    -- TODO when figure out brave devtools, go back to only using cmd+a in excel
                    -- AXValue replace isn't working in excel so use cmd+A is fine
                    -- *** FYI super cool to use this prompt in excel:
                    --   average of A1 to A12
                    --   (F2 edit then ask... as it types into cell the range selects!)
                    hs.eventtap.keyStroke({ "cmd" }, "a", 0) -- 0ms delay b/c by the time we get any response will be way long enoughk
                -- end
            end
            -- print("No selection or unsupported element.")
            return value
        end
    else
        hs.alert.show("Try using new axuielement selector approach as a fallback if system wide focused element fails to find the DevTools or otherwise")
        -- TODO WOULD HAVE TO BE APP SECIFIC:
        -- i.e. dev tools window literally has "DevTools" in title of an element on way down the specifier chain, here's an example though it will change:
        --
        -- app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1):group(1):group(1):group(1):group(1):group(1)
        --   :group(1):group(1):group(1):group(1):group(1):group(1):group(2):group(1):group(1):group(1):group(1):group(1):group(1)
        --   :group(1):group(1):group(2)
        --
        -- AXBlockQuoteLevel: 0<number>
        -- AXDOMClassList: [1: monospace<string>]
        -- AXDOMIdentifier: console-messages<string>
        -- AXElementBusy: false<bool>
        -- AXEnabled: true<bool>
        -- AXEndTextMarker: <hs.axuielement.axtextmarker>
        -- AXFocusableAncestor: AXGroup '' - Console panel<hs.axuielement>
        -- AXFocused: false<bool>
        -- AXLinkedUIElements: []
        -- AXRequired: false<bool>
        -- AXRoleDescription: group<string>
        -- AXSelected: false<bool>
        -- AXSelectedRows: []
        -- AXSelectedTextMarkerRange: <hs.axuielement.axtextmarkerrange>
        -- AXStartTextMarker: <hs.axuielement.axtextmarker>
        -- AXVisited: false<bool>
        -- ChromeAXNodeId: 666<string>
        --
        -- unique ref: app:window('DevTools - www.hammerspoon.org/docs/hs.task.html - wes private')
        --   :group('DevTools - www.hammerspoon.org/docs/hs.task.html - wes private'):group(''):group(''):group(''):scrollArea()
        --   :webArea('DevTools'):group('')

        -- FYI COULD SEARCH FOR title 'DevTools' and/or AXWebArea...

        print("No selection or unsupported element.")
        return ""
    end
end

return M
