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
