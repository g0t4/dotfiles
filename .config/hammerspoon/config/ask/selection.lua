local M = {}

function M.getSelectedTextThen(callbackWithSelectedText)
    -- TODO! turn this into a generic class that can take text out of any selected application's focused element, or otherwise specific to app
    --   AND then be able to turn around and edit/replace that text
    --   I can use this for far more than just ask-openai questions...
    --   I can actually start doing auto complete in EVERY APP! as I type in an app, if I can detect those typing events I can make my own global copilot!
    --     maybe even show floating window with a suggestion so I don't have to rely on each app's nuances to preview completions
    --     PLUS then it wouldn't get in the way!

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
    if app:name() == APPS.BraveBrowserBeta then
        hs.eventtap.keyStroke({ "cmd" }, "a", 0) -- 0ms delay b/c by the time we get any response will be way long enoughk
        -- FYI can do Edit => Select All if cmd+a isn't working for an app

        SearchForDevToolsTextArea(callbackWithSelectedText)
        return
    end

    if focusedElement then
        print("found systemWide AXFocusedUIElement: ", BuildHammerspoonLuaTo(focusedElement))
        local selectedText = focusedElement:attributeValue("AXSelectedText") -- < 0.4ms !!

        if selectedText and selectedText ~= "" then
            -- print("selected text found")
            callbackWithSelectedText(selectedText)
            return
        else
            local value = focusedElement:attributeValue("AXValue") -- < 0.4ms !!
            local name = app:name()
            if name == APPS.Excel then
                -- clear the text to simulate cut behavior (clear until response starts)
                -- could select all to simulate having copied it (so response replaces it too)
                -- excel assume no selection == replace all too
                focusedElement:setAttributeValue("AXValue", "") -- TODO not working in excel
                -- TODO why is setting AXValue empty causing menu to open in dev tools?
                -- FOR NOW allow just use cmd+a in Brave too (stops the context menu from showing... odd)
                -- if name == APPS.MicrosoftExcel then
                -- AXValue replace isn't working in excel so use cmd+A is fine
                -- *** FYI super cool to use this prompt in excel:
                --   average of A1 to A12
                --   (F2 edit then ask... as it types into cell the range selects!)
                hs.eventtap.keyStroke({ "cmd" }, "a", 0) -- 0ms delay b/c by the time we get any response will be way long enoughk
                -- end
            end
            -- print("No selection or unsupported element.")
            callbackWithSelectedText(value)
            return
        end
    else
        hs.alert.show("did not find system wide element, might need an app specific fix like Brave but for ..." .. app:name())
    end
    -- trigger select all which is needed to get/replace the user prompt/question
    -- local selected = app:selectMenuItem({ "Edit", "Select All" })
    -- if (not selected) then
    --     print("failed to select all")
    --     return
    -- end
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

    -- this time get selected text wasn't working, then it started working UGH! and nothing changed here:
    --    nothing changed in ATTRs either (below is what it was broken and not:
    --
    -- app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1):group(1):group(1):group(1):group(1):group(1)
    --   :group(1):group(1):group(1):group(2):group(1):group(1):group(2):group(1):group(1):group(1):group(1):group(1):group(1)
    --   :group(1):group(1):group(2)
    --
    -- ChromeAXNodeId: 6<string>
    --
    -- unique ref: app
    --   :window('DevTools - docs.google.com/document/d//edit?tab=t.0 - wes private')
    --   :group('DevTools - docs.google.com/document/d//edit?tab=t.0 - wes private')
    --   :group(''):group(''):group(''):scrollArea(''):webArea('DevTools'):group('')

    -- *** focused element reproduced with attrs from T inspect:
    -- WHEN FOCUSED ELEMENT WORKS ABOVE, it returns this for BuildHammerspoonLuaTo:
    -- 2025-04-05 16:38:39: focusedElement
    --    app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1):group(1):group(1):group(1):group(1):group(1)
    -- :group(1):group(1):group(1):group(2):group(1):group(1):group(2):group(1):group(1):group(1):group(1):group(1):group(1)
    -- :group(1):group(1):group(2):group(2):group(1):group(1):group(1):group(2):textArea(1)
    --
    --  LITERALLY THE TEXT BOX with the current line contents... I was able to dig down into it:
    --
    --  app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1):group(1):group(1):group(1):group(1):group(1)
    --   :group(1):group(1):group(1):group(2):group(1):group(1):group(2):group(1):group(1):group(1):group(1):group(1):group(1)
    --   :group(1):group(1):group(2):group(2):group(1):group(1):group(1):group(2):textArea(1)
    --
    -- AXBlockQuoteLevel: 0<number>
    -- AXDOMClassList: [
    --   1: cm-content<string>
    --   2: cm-lineWrapping<string>
    -- ]
    -- AXDescription: Console prompt<string>
    -- AXEditableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
    -- AXElementBusy: false<bool>
    -- AXEnabled: true<bool>
    -- AXEndTextMarker: <hs.axuielement.axtextmarker>
    -- AXFocusableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
    -- AXFocused: true<bool>
    -- AXHighestEditableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
    -- AXInvalid: false<string>
    -- AXLinkedUIElements: []
    -- AXRequired: false<bool>
    -- AXRoleDescription: text entry area<string>
    -- AXSelected: false<bool>
    -- AXSelectedRows: []
    -- AXSelectedTextMarkerRange: <hs.axuielement.axtextmarkerrange>
    -- AXStartTextMarker: <hs.axuielement.axtextmarker>
    -- AXValue: document.querySelectorAll("div.docs-material-colorpalette-colorswatch")<string>
    -- AXValueAutofillAvailable: false<bool>
    -- AXVisited: false<bool>
    -- ChromeAXNodeId: 174751<string>
    --
    -- AXChildren:
    -- AXGroup: '' desc:''
    --
    -- AXChildrenInNavigationOrder:
    -- AXGroup: '' desc:''
    --
    -- unique ref: app
    --   :window('DevTools - docs.google.com/document/d/-IO-/edit?tab=t.0 - wes private')
    --   :group('DevTools - docs.google.com/document/d/-IO-/edit?tab=t.0 - wes private')
    --   :group(''):group(''):group(''):scrollArea(''):webArea('DevTools'):group('')       --
    --

    -- *** ok DevTools web area has selected text! (assuming its selected?)
    -- app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1)
    --
    -- AXBlockQuoteLevel: 0<number>
    -- AXDOMClassList: []
    -- AXElementBusy: false<bool>
    -- AXEnabled: true<bool>
    -- AXEndTextMarker: <hs.axuielement.axtextmarker>
    -- AXFocused: false<bool>
    -- AXLinkedUIElements: []
    -- AXLoaded: true<bool>
    -- AXLoadingProgress: 1.0<number>
    -- AXRequired: false<bool>
    -- AXRoleDescription: HTML content<string>
    -- AXSelected: false<bool>
    -- AXSelectedRows: []
    -- AXSelectedText: document.querySelectorAll("div.docs-material-colorpalette-colorswatch")<string>
    -- AXSelectedTextMarkerRange: <hs.axuielement.axtextmarkerrange>
    -- AXStartTextMarker: <hs.axuielement.axtextmarker>
    -- AXTitle: DevTools<string>
    -- AXURL: [
    --   url: devtools://devtools/bundled/devtools_app.html?remoteBase=https://devtools.brave.com/serve_file/@/&targetType=tab&can_dock=true<string>
    --   __luaSkinType: NSURL<string>
    -- ]
    -- AXVisited: false<bool>
    -- ChromeAXNodeId: 1<string>
    --
    -- unique ref: app
    --   :window('DevTools - docs.google.com/document/d/-IO-/edit?tab=t.0 - wes private')
    --   :group('DevTools - docs.google.com/document/d/-IO-/edit?tab=t.0 - wes private')
    --   :group(''):group(''):group(''):scrollArea(''):webArea('DevTools')
end

return M
