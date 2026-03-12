local function percent_to_dmx(percent)
    local val = math.floor(percent / 100 * 65535)
    local high = math.floor(val / 256)
    local low = val % 256
    return high, low
end

local function temp_to_dmx(kelvin)
    -- 2800K = 0, 10000K = 65535
    local val = math.floor((kelvin - 2800) / (10000 - 2800) * 65535)
    val = math.max(0, math.min(65535, val))
    local high = math.floor(val / 256)
    local low = val % 256
    return high, low
end

local function set_lights(right_intensity, right_temp, left_intensity, left_temp)
    local ri_h, ri_l = percent_to_dmx(right_intensity)
    local rt_h, rt_l = temp_to_dmx(right_temp)
    local li_h, li_l = percent_to_dmx(left_intensity)
    local lt_h, lt_l = temp_to_dmx(left_temp)

    local channels = {}
    -- right light: channels 1-5
    channels[1] = ri_h
    channels[2] = ri_l
    channels[3] = rt_h
    channels[4] = rt_l
    channels[5] = 0 -- tint
    -- channels 6-20: unused
    for i = 6, 20 do channels[i] = 0 end
    -- left light: channels 21-25
    channels[21] = li_h
    channels[22] = li_l
    channels[23] = lt_h
    channels[24] = lt_l
    channels[25] = 0 -- tint

    local dmx = table.concat(channels, ",")
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx)
end

function StreamDeckBuild26()
    local temp = 5000
    set_lights(15, temp, 5, temp)
end

function StreamDeckDmxOff()
    hs.execute("/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
end
