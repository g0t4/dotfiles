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


local function set_light_channels(dmx_channels, base, intensity, temp)
    local ih, il = percent_to_dmx(intensity)
    local th, tl = temp_to_dmx(temp)
    dmx_channels[base]     = ih
    dmx_channels[base + 1] = il
    dmx_channels[base + 2] = th
    dmx_channels[base + 3] = tl
    dmx_channels[base + 4] = 0 -- tint
end

local function set_lights(right_intensity, right_temp, back_intensity, back_temp, left_intensity, left_temp)
    local dmx_channels = {}

    -- right light: base channel 1
    set_light_channels(dmx_channels, 1, right_intensity, right_temp)

    -- channels 6‑10: unused
    for i = 6, 10 do dmx_channels[i] = "" end

    -- back light: base channel 11
    set_light_channels(dmx_channels, 11, back_intensity, back_temp)

    -- channels 16‑20: unused
    for i = 16, 20 do dmx_channels[i] = "" end

    -- left light: base channel 21
    set_light_channels(dmx_channels, 21, left_intensity, left_temp)

    -- TODO how can I target a subset of channels without a massive comma delimited string?
    --    i.e. can't I send just 21 to 28? and not need the empty commas in between?
    local dmx_string = table.concat(dmx_channels, ",")
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx_string)
end

function StreamDeckBuild26()
    local temp = 5000
    set_lights(10, temp, 8, temp, 5, temp)
end

function StreamDeckDmxOff()
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
end
