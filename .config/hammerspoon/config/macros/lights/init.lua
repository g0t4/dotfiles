local function percent_to_dmx(percent)
    local value = math.floor(percent / 100 * 65535)
    local high = math.floor(value / 256)
    local low = value % 256
    return high, low
end

local function temp_to_dmx(kelvin)
    -- 2800K = 0, 10000K = 65535
    local dmx_value = math.floor((kelvin - 2800) / (10000 - 2800) * 65535)
    dmx_value = math.max(0, math.min(65535, dmx_value))
    local high_byte = math.floor(dmx_value / 256)
    local low_byte = dmx_value % 256
    return high_byte, low_byte
end


local function hue_to_dmx(degrees)
    -- 0-360 degrees mapped to 0-65535
    local val = math.floor(degrees / 360 * 65535)
    val = math.max(0, math.min(65535, val))
    return math.floor(val / 256), val % 256
end

---@param dmx_channels table<number, integer>
---@param channel_start integer
---@param params { intensity: number, temp: number }
local function set_cct_channels(dmx_channels, channel_start, params)
    local intensity_high_byte, intensity_low_byte = percent_to_dmx(params.intensity)
    local temp_high_byte, temp_low_byte = temp_to_dmx(params.temp)
    dmx_channels[channel_start] = intensity_high_byte
    dmx_channels[channel_start + 1] = intensity_low_byte
    dmx_channels[channel_start + 2] = temp_high_byte
    dmx_channels[channel_start + 3] = temp_low_byte
    dmx_channels[channel_start + 4] = 0 -- tint (hardcode 0 for now)
    dmx_channels[channel_start + 5] = 0 -- unused
    dmx_channels[channel_start + 6] = 0 -- unused
    dmx_channels[channel_start + 7] = 0 -- unused
end


local function set_hsl_channels(dmx_channels, channel_start, master_intensity, hue, saturation, lightness)
    local master_high_byte, master_low_byte = percent_to_dmx(master_intensity)
    print("master", master_high_byte, master_low_byte)
    local hue_high_byte, hue_low_byte = hue_to_dmx(hue)
    print("hue", hue_high_byte, hue_low_byte)
    local saturation_high_byte, saturation_low_byte = percent_to_dmx(saturation)
    print("sat", saturation_high_byte, saturation_low_byte)
    local lightness_high_byte, lightness_low_byte = percent_to_dmx(lightness)
    print("lightness", lightness_high_byte, lightness_low_byte)

    dmx_channels[channel_start] = master_high_byte
    dmx_channels[channel_start + 1] = master_low_byte
    dmx_channels[channel_start + 2] = hue_high_byte
    dmx_channels[channel_start + 3] = hue_low_byte
    dmx_channels[channel_start + 4] = saturation_high_byte
    dmx_channels[channel_start + 5] = saturation_low_byte
    dmx_channels[channel_start + 6] = lightness_high_byte
    dmx_channels[channel_start + 7] = lightness_low_byte
end

function StreamDeckBuild26()
    local temp = 5000

    -- light values
    local left = { intensity = 5, temp = temp }
    local right = { intensity = 10, temp = temp }
    local back = { master = 20, hue = 240, saturation = 100, lightness = 0 } -- rear/kick/accent

    local dmx_channels = {}

    -- left (key) light: CCT 16bit (uses 5/8 channels)
    set_cct_channels(dmx_channels, 1, left)

    -- right (fill) light: CCT 16bit (uses 5/8 channels)
    set_cct_channels(dmx_channels, 9, right)

    -- back light HSL 16bit (uses 8/8 channels)
    set_hsl_channels(dmx_channels, 17,
        back.master, back.hue, back.saturation, back.lightness)

    -- TODO how can I target a subset of channels without a massive comma delimited string?
    --    i.e. can't I send just 21 to 28? and not need the empty commas in between?
    local dmx_string = table.concat(dmx_channels, ",")
    local cmd = "/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx_string
    print(cmd)
    hs.execute(cmd)
end

function StreamDeckDmxOff()
    local cmd = "/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
    print(cmd)
    hs.execute(cmd)
end
