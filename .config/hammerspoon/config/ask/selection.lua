local M = {}

-- local t = require("config.times")

function M.getSelectedText()
    -- NOTES:
    --   selected text does not work in iTerm (at least not in nvim)... that'sfine as I am not using this at all in iterm... if I was I could just impl smth specific to iterm most likley...
    --   verified works in: Brave devtools, Script Debugger and Editor, (AXValue in iterm + nvim)

    -- Access the currently focused UI element
    -- ~ 6 to 10ms first call (sometimes <1ms too)
    --   then <1ms on back to back calls
    --   max was 25ms one time... still less than 30ms just to select text with keystroke!!!
    -- t.set_start_time()
    -- COOL dont even need to specify the app! just finds frontmost app's focused element!
    local focusedElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    -- t.print_elapsed("AXFocusedUIElement")

    if focusedElement then
        local selectedText = focusedElement:attributeValue("AXSelectedText") -- < 0.4ms !!

        if selectedText and selectedText ~= "" then
            print("selected text found")
            return selectedText
        else
            print("No selection or unsupported element.")
            local value = focusedElement:attributeValue("AXValue") -- < 0.4ms !!
            return value
        end
    else
        return "No focused element."
    end
end

return M
