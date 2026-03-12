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


local function set_lights(right_intensity, right_temp, left_intensity, left_temp)
    local right_intensity_high, right_intensity_low = percent_to_dmx(right_intensity)
    local right_temp_high,      right_temp_low      = temp_to_dmx(right_temp)
    local left_intensity_high,  left_intensity_low  = percent_to_dmx(left_intensity)
    local left_temp_high,       left_temp_low       = temp_to_dmx(left_temp)

    local dmx_channels = {}

    -- right light: channels 1‑5
    dmx_channels[1] = right_intensity_high
    dmx_channels[2] = right_intensity_low
    dmx_channels[3] = right_temp_high
    dmx_channels[4] = right_temp_low
    dmx_channels[5] = 0 -- tint

    -- channels 6‑20: unused
    for i = 6, 20 do
        dmx_channels[i] = 0
    end

    -- left light: channels 21‑25
    dmx_channels[21] = left_intensity_high
    dmx_channels[22] = left_intensity_low
    dmx_channels[23] = left_temp_high
    dmx_channels[24] = left_temp_low
    dmx_channels[25] = 0 -- tint

    local dmx_string = table.concat(dmx_channels, ",")
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx_string)
end

function StreamDeckBuild26()
    local temp = 5000
    set_lights(15, temp, 5, temp)
end

function StreamDeckDmxOff()
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
end
