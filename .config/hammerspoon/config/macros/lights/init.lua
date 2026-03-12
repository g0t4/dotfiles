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

local function set_cct_channels(dmx_channels, channel_start, intensity, temp)
    local intensity_high_byte, intensity_low_byte = percent_to_dmx(intensity)
    local temp_high_byte, temp_low_byte = temp_to_dmx(temp)
    dmx_channels[channel_start]     = intensity_high_byte
    dmx_channels[channel_start + 1] = intensity_low_byte
    dmx_channels[channel_start + 2] = temp_high_byte
    dmx_channels[channel_start + 3] = temp_low_byte
    dmx_channels[channel_start + 4] = 0 -- tint
end


local function set_hsl_channels(dmx_channels, channel_start, master_intensity, hue, saturation, lightness)
    local master_high_byte,     master_low_byte     = percent_to_dmx(master_intensity)
    local hue_high_byte,        hue_low_byte        = hue_to_dmx(hue)
    -- saturation range is 50-100%, so map 0-100% input to 50-100% DMX
    local sat_mapped = 50 + (saturation / 100 * 50)
    local saturation_high_byte, saturation_low_byte = percent_to_dmx(sat_mapped)
    -- lightness: 0 = pure color, 100 = white
    local lightness_high_byte,  lightness_low_byte  = percent_to_dmx(lightness)

    dmx_channels[channel_start]     = master_high_byte
    dmx_channels[channel_start + 1] = master_low_byte
    dmx_channels[channel_start + 2] = hue_high_byte
    dmx_channels[channel_start + 3] = hue_low_byte
    dmx_channels[channel_start + 4] = saturation_high_byte
    dmx_channels[channel_start + 5] = saturation_low_byte
    dmx_channels[channel_start + 6] = lightness_high_byte
    dmx_channels[channel_start + 7] = lightness_low_byte
end

local function set_lights(right_intensity, right_temp, back_opts, left_intensity, left_temp)
    local dmx_channels = {}

    -- right light: base channel 1 (CCT, 5 channels)
    set_cct_channels(dmx_channels, 1, right_intensity, right_temp)

    -- channels 6‑10: unused
    for i = 6, 10 do dmx_channels[i] = "" end

    -- back light: base channel 11 (HSL, 8 channels)
    set_hsl_channels(dmx_channels, 11,
        back_opts.master, back_opts.hue, back_opts.saturation, back_opts.lightness)

    -- channels 19‑20: unused
    for i = 19, 20 do dmx_channels[i] = "" end

    -- left light: base channel 21 (CCT, 5 channels)
    set_cct_channels(dmx_channels, 21, left_intensity, left_temp)

    -- TODO how can I target a subset of channels without a massive comma delimited string?
    --    i.e. can't I send just 21 to 28? and not need the empty commas in between?
    local dmx_string = table.concat(dmx_channels, ",")
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx_string)
end

function StreamDeckBuild26()
    local temp = 5000
    set_lights(10, temp, { master = 20, hue = 240, saturation = 100, lightness = 0 }, 5, temp)
end

function StreamDeckDmxOff()
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
end
