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
    dmx_channels[channel_start] = intensity_high_byte
    dmx_channels[channel_start + 1] = intensity_low_byte
    dmx_channels[channel_start + 2] = temp_high_byte
    dmx_channels[channel_start + 3] = temp_low_byte
    dmx_channels[channel_start + 4] = 0 -- tint (hardcode 0 for now)
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

local function set_lights(right_intensity, right_temp, back_opts, left_intensity, left_temp)
    local dmx_channels = {}

    -- right light: CCT 16bit (uses 5/8 channels)
    set_cct_channels(dmx_channels, 1, right_intensity, right_temp)

    -- back light HSL 16bit (uses 8/8 channels)
    set_hsl_channels(dmx_channels, 9,
        back_opts.master, back_opts.hue, back_opts.saturation, back_opts.lightness)

    -- left light: CCT 16bit (uses 5/8 channels)
    set_cct_channels(dmx_channels, 17, left_intensity, left_temp)

    -- TODO how can I target a subset of channels without a massive comma delimited string?
    --    i.e. can't I send just 21 to 28? and not need the empty commas in between?
    local dmx_string = table.concat(dmx_channels, ",")
    local cmd = "/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx_string
    print(cmd)
    hs.execute(cmd)
end

function StreamDeckBuild26()
    local temp = 5000
    set_lights(
        10, temp, -- right (fill)
        -- TODO lightness, seems to map to a temp value... how does that work? just on HSL 16 bit mode
        { master = 20, hue = 240, saturation = 100, lightness = 0 }, -- rear/kick/accent
        5, temp -- left (key)
    )
end

function StreamDeckDmxOff()
    local cmd = "/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
    print(cmd)
    hs.execute(cmd)
end
