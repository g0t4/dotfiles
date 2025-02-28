require("config.helpers")

function drawTextIcon(text)
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
        -- PRN? text = hs.styledtext.getStyledTextFromData(text, "html")
        -- https://www.hammerspoon.org/docs/hs.styledtext.html
        -- print("default font style:", hs.inspect(hs.styledtext.defaultFonts))
        -- Menlo
        local styledText = hs.styledtext.new(text, {
            font = {
                -- name = ".AppleSystemUIFont", -- THIS matches default, and it looks good (tight, not spaced out)
                --    TODO can I lookup the default font's name?
                -- name = "Helvetica"/"Helvetica Neue", -- these are 10-20% bigger
                -- name = "SF Pro Display", (not this, this is taller)
                size = 26
            },
            color = { red = 1, green = 1, blue = 1, alpha = 1 },
            paragraphStyle = {
                alignment = "center",
            },
        })

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
    -- FYI https://www.hammerspoon.org/docs/hs.canvas.html#attributes
    return canvas:imageFromCanvas()
end
