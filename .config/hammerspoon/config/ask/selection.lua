local M = {}

function M.getSelectedText()
    -- OMG I can return both the selection AND the value of the textbox... WITHOUT using the clipboard at FUCKING ALL
    -- AND THIS APPEARS TO PERFORM at least somewhat well
    --

    local socket = require("socket")
    local start_time = socket.gettime()

    local function print_elapsed(message)
        local elapsed_time = socket.gettime() - start_time
        print(string.format("%s: %.6f seconds", message, elapsed_time))
    end

    -- Access the currently focused UI element
    -- ~10ms first call
    --   then <1ms on back to back calls
    --   max was 25ms one time... still less than 30ms just to select text with keystroke!!!
    local focusedElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    print_elapsed("focusedElement")
    -- print("focusedElement", focusedElement)

    if focusedElement then
        local selectedText = focusedElement:attributeValue("AXSelectedText") -- < 0.4ms !!
        print_elapsed("AXSeelctedText")

        if selectedText and selectedText ~= "" then
            return selectedText
        else
            -- print("No selection or unsupported element.")
            local value = focusedElement:attributeValue("AXValue")
            print_elapsed("AXValue")
            return value
        end
    else
        return "No focused element."
    end
end

return M
