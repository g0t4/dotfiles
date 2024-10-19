-- Helper function to convert hex to RGB
local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

-- Helper function to convert RGB to HSL
local function rgb_to_hsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = (max + min) / 2, (max + min) / 2, (max + min) / 2

    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

-- Helper function to convert HSL to RGB
local function hsl_to_rgb(h, s, l)
    if s == 0 then
        return l, l, l
    end

    local function hue_to_rgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1 / 6 then return p + (q - p) * 6 * t end
        if t < 1 / 2 then return q end
        if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
        return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q

    local r = hue_to_rgb(p, q, h + 1 / 3)
    local g = hue_to_rgb(p, q, h)
    local b = hue_to_rgb(p, q, h - 1 / 3)

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- Helper function to convert RGB to HEX
local function rgb_to_hex(r, g, b)
    return string.format("#%02x%02x%02x", r, g, b)
end

-- Function to desaturate (reduce saturation) and make a color grayer
local function desaturate_color_hex(hex_color, desaturation_factor)
    -- Convert hex to RGB
    local r, g, b = hex_to_rgb(hex_color)

    -- Convert RGB to HSL
    local h, s, l = rgb_to_hsl(r, g, b)

    -- Reduce the saturation by the desaturation_factor
    s = s * (1 - desaturation_factor)

    -- Convert back to RGB
    local new_r, new_g, new_b = hsl_to_rgb(h, s, l)

    -- Return the new color in hex format
    return rgb_to_hex(new_r, new_g, new_b)
end

-- Example usage: apply desaturation to colors (reduce saturation by 50%)
-- local new_rainbow_red = desaturate_color_hex("#E06C75", 0.5)    -- Hex for #E06C75

return {
    hex_to_rgb = hex_to_rgb,
    rgb_to_hsl = rgb_to_hsl,
    hsl_to_rgb = hsl_to_rgb,
    rgb_to_hex = rgb_to_hex,
    desaturate_color_hex = desaturate_color_hex
}
