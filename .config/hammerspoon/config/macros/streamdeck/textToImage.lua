require("config.helpers")

function merge(t1, t2)
    local res = {}
    for k, v in pairs(t1) do res[k] = v end
    for k, v in pairs(t2) do res[k] = v end
    return res
end

--
-- local t1 = { a = 1, b = 2 }
-- local t2 = { b = 3, c = 4 }
-- local merged = merge(t1, t2)
-- print(hs.inspect(merged))

---@param text string
---@param deck DeckController
---@param style table|nil # pass custom style table (https://www.hammerspoon.org/docs/hs.styledtext.html)
---@return hs.image
function drawTextIcon(text, deck, style)
    -- PRN? text = hs.styledtext.getStyledTextFromData(text, "html")

    local width = deck.buttonSize.w
    local height = deck.buttonSize.h
    -- todo based on device button size (4+ has 120x120, XL has 96x96)
    -- use canvas for text on images on icons! COOL
    --   streamdeck works off of images only for the buttons, makes 100% sense
    local canvas = hs.canvas.new({ x = 0, y = 0, w = width, h = height })
    assert(canvas ~= nil, "canvas is nil")

    -- if false then
    --     -- PRN add background color a parameter
    --     -- right now it's just black so I don't need this
    --     -- see hs.canvas element attributes for shapes/options:
    --     --   https://www.hammerspoon.org/docs/hs.canvas.html#attributes
    --     table.insert(canvas, {
    --         type = "rectangle",
    --         action = "fill",
    --         fillColor = { hex = "#b22793", alpha = 1 },
    --         -- many ways to set color: https://www.hammerspoon.org/docs/hs.drawing.color.html
    --     })
    -- end

    if type(text) == "string" then
        if style == nil then
            -- TODO merge style table with defaults:
            style = {
                font = {
                    -- name = ".AppleSystemUIFont", -- THIS matches default, and it looks good (tight, not spaced out)
                    --    TODO can I lookup the default font's name?
                    -- name = "Helvetica"/"Helvetica Neue", -- these are 10-20% bigger
                    -- name = "SF Pro Display", (not this, this is taller)
                    size = 24
                },
                color = { hex = "ffffff", alpha = 1 },
                paragraphStyle = {
                    alignment = "center",
                },
            }
        end
        local styledText = hs.styledtext.new(text, style)
        local y = 0
        -- -- FYI size estimate is off on "Clear\nConsole" but appears good for ClockButton?! (has 3 lines)
        -- if true then
        --     local estimatedSize = hs.drawing.getTextDrawingSize(styledText)
        --     print("estimatedSize(", text, ")", hs.inspect(estimatedSize))
        --     if estimatedSize.h < height then
        --         -- shift down by half of diff
        --         local diff = height - estimatedSize.h
        --         y = diff / 2
        --         print("  y", y)
        --     end
        -- end

        table.insert(canvas, {
            type = "text",
            text = styledText,
            frame = { x = 0, y = y, w = width, h = height },
        })
    elseif isStyledText(text) then
        table.insert(canvas, {
            type = "text",
            text = text,
            frame = { x = 0, y = 0, w = width, h = height },
        })
    end
    return canvas:imageFromCanvas()
end
