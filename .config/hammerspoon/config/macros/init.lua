require("config._packages")
local debug = require("devtools.debug")
local log = require("config.logs").hammerspoons()
local ensure_in_coroutine = require("devtools.co.ensure_in_coroutine")

local M = {}
local openTasks = {}

---Open a filesystem path with its default handler, without shell parsing.
---@param path string Use literal spaces; ~/ expands to the current user's Home.
---@return boolean started
function StreamDeckOpen(path)
    if type(path) ~= "string" or path == "" then
        hs.alert.show("StreamDeckOpen needs a file or folder path")
        return false
    end
    if path == "~" then
        path = os.getenv("HOME")
    elseif path:sub(1, 2) == "~/" then
        path = os.getenv("HOME") .. path:sub(2)
    end
    local task
    task = hs.task.new("/usr/bin/open", function(code, _, stderr)
        openTasks[task] = nil
        if code ~= 0 then
            log:error("StreamDeckOpen failed:", path, stderr)
            hs.alert.show("Could not open path; see Hammerspoon log")
        end
    end, {"--", path})
    if task then
        openTasks[task] = true
        if task:start() then return true end
        openTasks[task] = nil
    end
    log:error("StreamDeckOpen could not start:", path)
    hs.alert.show("Could not start open")
    return false
end

---@param path? string Directory to open, or file to select; defaults to Home.
function StreamDeckPipRot(path)
    require("config.launcher.pip_rot").open(path)
end

-- macOS-only helper for toggling bluetooth audio devices (e.g. "Wes's AirPods Pro #2")
-- via pyobjc (pyobjc-framework-IOBluetooth). Devices are matched by partial name,
-- first match wins. macOS auto-selects a freshly-connected bluetooth output as the
-- default and reverts the default when it disconnects, so this is really a
-- connect/disconnect of the bluetooth link. Script: config/macros/streamdeck/airpods.py
local python_exe = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.venv/bin/python3"
local airpods_script = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.config/hammerspoon/config/macros/streamdeck/airpods.py"

---Default the device-name substring to the AirPods Pro #2.
---@param name_substring string|nil
---@return string
local function default_name(name_substring)
    if name_substring == nil or name_substring == "" then
        return "AirPods Pro #2"
    end
    return name_substring
end

---Find the audio output device registered with CoreAudio whose name contains
---`name_substring` (first match).
---@param name_substring string
---@return hs.audiodevice|nil
local function find_audio_device(name_substring)
    for _, device in ipairs(hs.audiodevice.allOutputDevices()) do
        if (device:name() or ""):find(name_substring, 1, true) then
            return device
        end
    end
    return nil
end

---Run the IOBluetooth helper script.
---@param command string "connect" or "disconnect"
---@param name_substring string
---@return boolean true on success
local function run_airpods(command, name_substring)
    local ok, output = hs.execute(python_exe .. " " .. airpods_script .. " " .. command .. " '" .. name_substring .. "' 2>&1")
    if not ok then
        hs.alert.show("Bluetooth " .. command .. " failed (" .. name_substring .. "):\n" .. (output or ""))
        log:error("bluetooth", command, "failed:", name_substring, output)
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

---Connect the bluetooth device whose name contains `name_substring` (first match).
---@param name_substring string
---@return boolean true if now connected
function StreamDeckConnectAudioDevice(name_substring)
    name_substring = default_name(name_substring)
    if find_audio_device(name_substring) then
        return true -- already connected
    end
    local ok = run_airpods("connect", name_substring)
    if ok then
        hs.alert.show("Connecting " .. name_substring .. "...")
    end
    return ok
end

---Disconnect the bluetooth device whose name contains `name_substring` (first match).
---macOS reverts the default output automatically.
---@param name_substring string
---@return boolean true if now disconnected
function StreamDeckDisconnectAudioDevice(name_substring)
    name_substring = default_name(name_substring)
    if not find_audio_device(name_substring) then
        return true -- already disconnected
    end
    local ok = run_airpods("disconnect", name_substring)
    if ok then
        hs.alert.show("Audio output: disconnected " .. name_substring)
    end
    return ok
end

---Toggle the bluetooth device whose name contains `name_substring` (first match)
---as the default audio output device. If it is already the default, disconnects
---it (macOS reverts the previous default). Otherwise connects it (macOS
---auto-selects it as the default).
---@param name_substring string
---@return boolean true if the device is now the default output
function StreamDeckToggleAudioDevice(name_substring)
    name_substring = default_name(name_substring)
    local device = find_audio_device(name_substring)
    local default = hs.audiodevice.defaultOutputDevice()
    local is_default = device and default and default:name() == device:name()

    if is_default then
        return StreamDeckDisconnectAudioDevice(name_substring)
    end

    local connect_ok = StreamDeckConnectAudioDevice(name_substring)
    -- CoreAudio registers the audio output device shortly after IOBluetooth
    -- reports the bluetooth link as connected, so poll briefly for it.
    local connected = find_audio_device(name_substring)
    local waited_ms = 0
    while not connected and waited_ms < 3000 do
        hs.timer.usleep(250)
        waited_ms = waited_ms + 250
        connected = find_audio_device(name_substring)
    end
    if connected then
        connected:setDefaultOutputDevice()
        hs.alert.show("Audio output: " .. connected:name())
        return true
    end
    return connect_ok -- connection initiated but CoreAudio hasn't registered yet
end

---Backward-compatible AirPods Pro #2 wrappers.
function StreamDeckConnectAirPodsPro2()
    return StreamDeckConnectAudioDevice("AirPods Pro #2")
end

function StreamDeckDisconnectAirPodsPro2()
    return StreamDeckDisconnectAudioDevice("AirPods Pro #2")
end

function StreamDeckToggleAirPodsPro2()
    return StreamDeckToggleAudioDevice("AirPods Pro #2")
end

function nudge_human_to_check_log()
    -- leave as black alert
    hs.alert.show("check " .. log.basename, nil, nil, 5)
end

local function red_alert(message)
    -- I routinely miss the black defaultStyle... so for important messages I should make it red!
    hs.alert.show(message, { fillColor = { red = 1, green = 0, blue = 0 } })
end

---@param lua_code_string string
function StreamDeckKeyboardMaestroRunner(lua_code_string)
    log:info("StreamDeckKeyboardMaestroRunner called with: " .. hs.inspect(lua_code_string)) -- FYI inspect is explicit here so a string is quoted in output
    -- USED in KM Macros => look at kmsync file:
    --    plutil -p Keyboard\ Maestro\ Macros.kmsync  | grep "StreamDeckKeyboardMaestroRunner"

    -- FYI easy to miss failures when using KM to call hs command
    -- - hs command echoes back to caller (not hs console)
    -- - info level prints become a nuissance
    -- - so I inevitably silence outputs in KM (b/c no good way to decide when and what to show)
    -- - THUS => use a log file, especially for info level logs
    -- - + egregious and unhandled exceptions poke the user (i.e. hs.alert.show)
    local is_empty = lua_code_string == nil or lua_code_string:match("^%s*$")
    if is_empty then
        local message = "no code provided to StreamDeckKeyboardMaestroRunner: " .. hs.inspect(lua_code_string)
        log:error(message)
        red_alert(message)
        return
    end

    ensure_in_coroutine(function()
        local context = lua_code_string
        local has_whitespace = context:find("%s")
        if has_whitespace then
            context = "`" .. context .. "`"
        end

        log:set_coroutine_context(context)
        log:divider("start")

        local ok, result = xpcall(
            function()
                local func, error_message = load(lua_code_string) -- load lua here so invalid lua code failures are logged too
                if error_message then
                    log:error("load lua code failed", error_message)
                    nudge_human_to_check_log()
                    return
                end
                func()
            end,
            full_traceback_xpcall
        )
        if ok then
            return
        end
        nudge_human_to_check_log()
        log:error("StreamDeckKeyboardMaestroRunner unhandled error", result)
    end)
end

require("config.macros.brave")
require("config.macros.fcpx")
require("config.macros.iterm")
require("config.macros.google-docs")
require("config.macros.msft_office")
require("config.macros.screenpal")
require("config.macros.parallels")
require("config.macros.hammerspoon")
require("config.macros.iina")
require("config.macros.frontmost")
require("config.macros.sdeck_config_app")
require("config.macros.macos")
require("config.macros.lights")

return M
