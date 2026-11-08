local log = require("config.logs").hammerspoons()
local python_exe = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.venv/bin/python3"
local airpods_script = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.config/hammerspoon/config/macros/macos/airpods.py"

---Find the audio output device registered with CoreAudio whose name matches
---`name_pattern` (first match).
---@param name_pattern string
---@return hs.audiodevice|nil
local function find_audio_device(name_pattern)
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if (device:name() or ""):find(name_pattern, 1) then
            return device
        end
    end
    return nil
end

---Run the IOBluetooth helper script.
---@param command string "connect" or "disconnect"
---@param name_pattern string
---@return boolean true on success
local function run_airpods(command, name_pattern)
    local ok, output = hs.execute(python_exe .. " " .. airpods_script .. " " .. command .. " '" .. name_pattern .. "' 2>&1")
    if not ok then
        hs.alert.show("Bluetooth " .. command .. " failed (" .. name_pattern .. "):\n" .. (output or ""))
        log:error("bluetooth", command, "failed:", name_pattern, output)
        return false
    end
    return true
end

---Print every audio output device CoreAudio currently sees, with its name and
---UID. Useful for debugging when a device (e.g. bluetooth AirPods) isn't
---showing up in StreamDeckToggleAudioDevice.
function StreamDeckListAudioDevices()
    local lines = {}
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        local name = device:name() or "?"
        local uid = device:uid() or "?"
        lines[#lines + 1] = ("%s  (%s)"):format(name, uid)
    end
    local output = "Audio output devices:\n" .. table.concat(lines, "\n")
    hs.alert.show(output)
    return output
end

---Connect the bluetooth device whose name matches `name_pattern` (first match).
---@param name_pattern string
---@return boolean true if now connected
function StreamDeckConnectAudioDevice(name_pattern)
    if find_audio_device(name_pattern) then
        return true -- already connected
    end
    local ok = run_airpods("connect", name_pattern)
    if ok then
        hs.alert.show("Connecting " .. name_pattern .. "...")
    end
    return ok
end

---Disconnect the bluetooth device whose name matches `name_pattern` (first match).
---macOS reverts the default output automatically.
---@param name_pattern string
---@return boolean true if now disconnected
function StreamDeckDisconnectAudioDevice(name_pattern)
    if not find_audio_device(name_pattern) then
        return true -- already disconnected
    end
    local ok = run_airpods("disconnect", name_pattern)
    if ok then
        hs.alert.show("Audio output: disconnected " .. name_pattern)
    end
    return ok
end

---Toggle the bluetooth device whose name matches `name_pattern` (first match)
---as the default audio output device. If it is already the default, disconnects
---it (macOS reverts the previous default). Otherwise connects it (macOS
---auto-selects it as the default).
---@param name_pattern string
---@return boolean true if the device is now the default output
function StreamDeckToggleAudioDevice(name_pattern)
    local device = find_audio_device(name_pattern)
    local default = hs.audiodevice.defaultOutputDevice()
    local is_default = device and default and default:name() == device:name()

    if is_default then
        return StreamDeckDisconnectAudioDevice(name_pattern)
    end

    local connect_ok = StreamDeckConnectAudioDevice(name_pattern)
    -- CoreAudio registers the audio output device shortly after IOBluetooth
    -- reports the bluetooth link as connected, so poll briefly for it.
    local connected = find_audio_device(name_pattern)
    local waited_ms = 0
    while not connected and waited_ms < 3000 do
        hs.timer.usleep(250)
        waited_ms = waited_ms + 250
        connected = find_audio_device(name_pattern)
    end
    if connected then
        connected:setDefaultOutputDevice()
        hs.alert.show("Audio output: " .. connected:name())
        return true
    end
    return connect_ok -- connection initiated but CoreAudio hasn't registered yet
end

local AIRPODS = {
    PRO = "AirPods Pro$",
    PRO_2 = "AirPods Pro #2$",
}

function StreamDeckConnectAirPodsPro2()
    return StreamDeckConnectAudioDevice(AIRPODS.PRO_2)
end

function StreamDeckDisconnectAirPodsPro2()
    return StreamDeckDisconnectAudioDevice(AIRPODS.PRO_2)
end

function StreamDeckToggleAirPodsPro()
    return StreamDeckToggleAudioDevice(AIRPODS.PRO)
end

function StreamDeckToggleAirPodsPro2()
    return StreamDeckToggleAudioDevice(AIRPODS.PRO_2)
end
