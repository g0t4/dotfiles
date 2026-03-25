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

local function hue_degrees_to_dmx(degrees)
    -- 0-360 degrees mapped to 0-65535
    local val = math.floor(degrees / 360 * 65535)
    val = math.max(0, math.min(65535, val))
    return math.floor(val / 256), val % 256
end

---@param dmx_channels table<number, integer>
---@param channel_start integer
---@param params { intensity: number, temp: number }
local function set_cct_16bit_channels(dmx_channels, channel_start, params)
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

---@param dmx_channels table<number, integer>
---@param channel_start integer
---@param params { master: number, hue: number, saturation: number, lightness: number }
local function set_hsl_16bit_channels(dmx_channels, channel_start, params)
    local master_high_byte, master_low_byte = percent_to_dmx(params.master)
    print("master", master_high_byte, master_low_byte)

    local hue_high_byte, hue_low_byte = hue_degrees_to_dmx(params.hue)
    print("hue", hue_high_byte, hue_low_byte)

    local sat_high_byte, sat_low_byte = percent_to_dmx(params.saturation)
    print("sat", sat_high_byte, sat_low_byte)

    local light_high_byte, light_low_byte = percent_to_dmx(params.lightness)
    print("lightness", light_high_byte, light_low_byte)

    dmx_channels[channel_start] = master_high_byte
    dmx_channels[channel_start + 1] = master_low_byte
    dmx_channels[channel_start + 2] = hue_high_byte
    dmx_channels[channel_start + 3] = hue_low_byte
    dmx_channels[channel_start + 4] = sat_high_byte
    dmx_channels[channel_start + 5] = sat_low_byte
    dmx_channels[channel_start + 6] = light_high_byte
    dmx_channels[channel_start + 7] = light_low_byte
end

function StreamDeckBuild26()
    local temp = 5000

    -- light values
    local left = { intensity = 5, temp = temp }
    local right = { intensity = 20, temp = temp }
    --
    -- don't need this for now, and this fixture is the finicky one... so I am done for today!
    -- local back = { master = 20, hue = 220, saturation = 100, lightness = 0 } -- rear/kick/accent

    local dmx_channels = {}
    set_cct_16bit_channels(dmx_channels, 1, left)
    set_cct_16bit_channels(dmx_channels, 9, right)
    -- set_hsl_16bit_channels(dmx_channels, 17, back)

    -- TODO how can I target a subset of channels without a massive comma delimited string?
    --    i.e. can't I send just 21 to 28? and not need the empty commas in between?
    local dmx_string = table.concat(dmx_channels, ",")
    local cmd = "/opt/homebrew/bin/ola_set_dmx -u 1 --dmx " .. dmx_string
    print(cmd)
    hs.execute(cmd)
end

function StreamDeckDmxOff()
    -- DO NOT LEAVE SPACES BETWEEN the comma separate list of values... will not send everything after a space!
    local cmd = "/opt/homebrew/bin/ola_set_dmx -u 1 --dmx 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
    print(cmd)
    hs.execute(cmd)
end
