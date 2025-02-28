require("config.helpers")


---@param text string
---@param style table|nil
---@return hs.image
function drawTextIcon(text, style)
    -- PRN? text = hs.styledtext.getStyledTextFromData(text, "html")

    local width = 96
    local height = 96
    -- todo based on device button size (4+ has 120x120, XL has 96x96)
    -- use canvas for text on images on icons! COOL
    --   streamdeck works off of images only for the buttons, makes 100% sense
    local canvas = hs.canvas.new({ x = 0, y = 0, w = width, h = height })
    assert(canvas ~= nil, "canvas is nil")

    canvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0, green = 0, blue = 0, alpha = 1 }, -- Background color
    }

    --    hs.styledtext.getStyledTextFromData(data, [type]) w/ type = "html"!
    if type(text) == "string" then
        if style == nil then
            -- https://www.hammerspoon.org/docs/hs.styledtext.html
            -- FYI https://www.hammerspoon.org/docs/hs.canvas.html#attributes
            -- print("default font style:", hs.inspect(hs.styledtext.defaultFonts))
            -- Menlo
            style = {
                font = {
                    -- name = ".AppleSystemUIFont", -- THIS matches default, and it looks good (tight, not spaced out)
                    --    TODO can I lookup the default font's name?
                    -- name = "Helvetica"/"Helvetica Neue", -- these are 10-20% bigger
                    -- name = "SF Pro Display", (not this, this is taller)
                    size = 24
                },
                color = { red = 1, green = 1, blue = 1, alpha = 1 },
                paragraphStyle = {
                    alignment = "center",
                },
            }
        end
        local styledText = hs.styledtext.new(text, style)

        canvas[2] = {
            type = "text",
            text = styledText,
            frame = { x = 0, y = 0, w = width, h = height },
        }
    elseif isStyledText(text) then
        canvas[2] = {
            type = "text",
            text = text,
            frame = { x = 0, y = 0, w = width, h = height },
        }
    end
    return canvas:imageFromCanvas()
end
