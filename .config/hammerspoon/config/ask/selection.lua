local M = {}

---@param callbackWithSelectedText function
function M.getSelectedTextThen(callbackWithSelectedText)
    -- FYI I have observed executing this function from within hammerspoon's Console window, leads to the Window being the focusedElement
    --   whereas with a StreamDeck button it correctly finds the textbox below the logs to be the correct focused element (when it is and I trigger the completions helper for HS lua help)

    -- TODO! turn this into a generic class that can take text out of any selected application's focused element, or otherwise specific to app
    --   AND then be able to turn around and edit/replace that text
    --   I can use this for far more than just ask-openai questions...
    --   I can actually start doing auto complete in EVERY APP! as I type in an app, if I can detect those typing events I can make my own global copilot!
    --     maybe even show floating window with a suggestion so I don't have to rely on each app's nuances to preview completions
    --     PLUS then it wouldn't get in the way!

    -- NOTES:
    --   selected text does not work in iTerm (at least not in nvim)... that'sfine as I am not using this at all in iterm... if I was I could just impl smth specific to iterm most likley...
    --   verified works in: Brave devtools, Script Debugger and Editor, (AXValue in iterm + nvim)

    local app = hs.application.frontmostApplication()
    if app:name() == APPS.BraveBrowserBeta then
        SearchForDevToolsTextArea(callbackWithSelectedText)
        return
    end

    -- Access the currently focused UI element
    -- ~ 6 to 10ms first call (sometimes <1ms too)
    --   then <1ms on back to back calls
    --   max was 25ms one time... still less than 30ms just to select text with keystroke!!!
    -- COOL dont even need to specify the app! just finds frontmost app's focused element!
    local focusedElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    -- FYI systemWideElement's attributeValue's "AXFocusedApplication" comes back nil for devtools
    --   issue might be with some apps when using systemWideElement!
    --   PRN... try using frontmost app's AXFocusedUIElement and see if it works reliably?
    --   it appears that systemWide route is a separate macOS API, might even be this one:
    --      https://developer.apple.com/documentation/applicationservices/1462095-axuielementcreatesystemwide

    if focusedElement then
        -- print("found systemWide AXFocusedUIElement: ", BuildHammerspoonLuaTo(focusedElement))
        local selectedText = focusedElement:attributeValue("AXSelectedText") -- < 0.4ms !!

        if selectedText and selectedText ~= "" then
            callbackWithSelectedText(selectedText, focusedElement)
            return
        else
            local value = focusedElement:attributeValue("AXValue") -- < 0.4ms !!
            callbackWithSelectedText(value, focusedElement)
            return
        end
    else
        hs.alert.show("did not find system wide element, might need an app specific fix like Brave but for ..." .. app:name())
    end
end

return M
