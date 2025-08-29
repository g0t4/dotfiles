---@param original table
---@param seen table|nil
---@return table
function deep_clone(original, seen)
    if type(original) ~= "table" then return original end
    if seen and seen[original] then return seen[original] end

    local copy = {}
    seen = seen or {}
    seen[original] = copy

    for k, v in pairs(original) do
        copy[k] = deep_clone(v, seen)
    end

    return copy
end

---@param defaults table
---@param overrides table|nil
---@return table
function merge_shallow(defaults, overrides)
    if overrides == nil or overrides == {} then
        return defaults
    end

    local merged = deep_clone(defaults)
    for k, v in pairs(overrides) do
        -- PRN change to merge_deep?
        merged[k] = v
    end
    return merged
end

RedText = { color = { hex = "#FF0000" } }
TinyText = { font = { size = 14 } }
ExtraSmallText = {
    font = { size = 18 },
    -- shadow = { offset = { h = 3, w = 3 } }, -- gives a slight outline to text
    --
    -- -- interesting too but so small it loses its color... I think I just need black text for my case
    -- strokeColor = { hex = "#000000" },-- , alpha = 0.5 },
    -- strokeWidth = 4,
}
SmallBlackText = {
    font = { size = 20 },
    color = { hex = "#000000" },
}
SmallText = { font = { size = 20 } } -- looks good with one blank line before two lines of text
MediumText = { font = { size = 24 } }
LargeText = { font = { size = 30 } }
LargeBlackText = { font = { size = 30 }, color = { hex = "#000000" } }
ExtraLargeText = { font = { size = 40 } }

function pageLeftImage(deck)
    return drawTextIcon("<", deck, { font = { size = 50 } })
end

function pageRightImage(deck)
    return drawTextIcon(">", deck, { font = { size = 50 } })
end

--
-- local t1 = { a = 1, b = 2 }
-- local t2 = { b = 3, c = 4 }
-- local merged = merge(t1, t2)
-- print(hs.inspect(merged))

---@param text string
---@param deck DeckController
---@param passedStyle table|nil # pass custom style table (https://www.hammerspoon.org/docs/hs.styledtext.html)
---@param backgroundImage hs.image|nil # background image to draw on top of
---@return hs.image
function drawTextIcon(text, deck, passedStyle, backgroundImage)
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
    if backgroundImage then
        table.insert(canvas, {
            type = "image",
            image = backgroundImage,
            frame = { x = 0, y = 0, w = width, h = height },
        })
    end

    if type(text) == "string" then
        local defaultStyle = {
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
        local mergedStyle = merge_shallow(defaultStyle, passedStyle)
        local styledText = hs.styledtext.new(text, mergedStyle)
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
    elseif is_styled_text(text) then
        table.insert(canvas, {
            type = "text",
            text = text,
            frame = { x = 0, y = 0, w = width, h = height },
        })
    end
    return canvas:imageFromCanvas()
end

function hsIconWithText(icon, text, deck, style)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, style, image)
end

function hsIconWithTinyText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, TinyText, image)
end

function hsIconWithExtraSmallText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, ExtraSmallText, image)
end

function hsIconWithSmallText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, SmallText, image)
end

function hsIconWithSmallBlackText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, SmallBlackText, image)
end

function hsIconWithExtraLargeText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, ExtraLargeText, image)
end

function hsIconWithLargeText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, LargeText, image)
end

function hsIconWithLargeBlackText(icon, text, deck)
    local image = hsIcon(icon)
    return drawTextIcon(text, deck, LargeBlackText, image)
end

---@param deck DeckController
---@return hs.canvas
function newButtonCanvas(deck)
    local canvas = hs.canvas.new({ x = 0, y = 0, w = deck.buttonSize.w, h = deck.buttonSize.h })
    assert(canvas ~= nil, "canvas is not nil")
    return canvas
end

---@param hexColor string
---@param deck DeckController
---@param label string|nil
---@return hs.image
function hsCircleIcon(hexColor, deck, label)
    local canvas = newButtonCanvas(deck)
    canvas[1] = {
        type = "circle",
        action = "fill", -- action = "strokeAndFill", -- don't need outline (yet?)
        fillColor = { hex = hexColor },
        -- strokeColor = hexColor,

        -- center = { x = "50%", y = "50%" }, -- this is the default and is perfect
        -- TODO radius = 90% -- default is 50%
        radius = "40%",
    }
    if label then
        label = "\n" .. label
        local styledText = hs.styledtext.new(label, {
            font = {
                -- PERFECT SIZE FOR 96x96 XL buttons... figure out PLUS later (IIGC just increase size a smidge)
                size = 26,
            },
            paragraphStyle = {
                alignment = "center",
            },
            color = { hex = "#000000" },
        })
        canvas[2] = {
            type = "text",
            text = styledText,
        }
    end
    return canvas:imageFromCanvas()
end
