require("config.helpers.finder")

local CAPTURE_DIR_SETTINGS_KEY = "screencapture_directory"

-- read the value:
--   defaults read org.hammerspoon.Hammerspoon screencapture_directory
-- print("settings bundle", hs.settings.bundleID) => org.hammerspoon.Hammerspoon

function getDefaultPhotosDir()
    return os.getenv("HOME") .. "/Pictures/Screencaps"
end

function setPhotosDir()
    local dir = getSelectedFinderDirectories()
    if dir == nil or #dir == 0 then
        hs.alert.show("No directory selected")
    else
        local firstDir = dir[1]
        -- TODO only allow directories => intermediate func for this
        hs.settings.set(CAPTURE_DIR_SETTINGS_KEY, firstDir)
        local message = "Capture dir is now: " .. firstDir
        if #dir > 1 then
            message = "multiple dirs selected, using first: " .. firstDir
        end
        hs.alert.show(message)
    end
end

function resetPhotosDir()
    hs.settings.clear(CAPTURE_DIR_SETTINGS_KEY)
end

local function getCaptureDirectory()
    return hs.settings.get(CAPTURE_DIR_SETTINGS_KEY) or getDefaultPhotosDir()
end

---@param extension? string
---@param image_tag? string -- added to filename, to give context about what was captured
---@param capture_sub_dir? string -- use nested directory to group related screen caps
---@return string filename
function get_screencapture_filename(extension, image_tag, capture_sub_dir)
    extension = extension or "png"

    -- FYI file sizes verified to match macOS keyboard shortcuts for screencap
    --   probably b/c macOS uses exact same args to screencapture cmd

    -- TODO how about have shadow be when I hold down option key and off by default?

    local frontmostapp = hs.application.frontmostApplication()
    local appName = frontmostapp:name()

    -- I hate having seconds on the screencap UNLESS I have multiple from the same minute
    local filename = os.date("%Y-%m-%d %Hh%Mm")
    if appName ~= nil then
        filename = filename .. "." .. appName
    end

    if image_tag ~= nil then
        filename = filename .. "." .. image_tag
    end

    -- check if capture directory exists, if not WARN and abort
    local capture_dir = getCaptureDirectory()
    if not hs.fs.attributes(capture_dir) then
        local message = "Screencap directory does not exist, please create it OR reset it: "
            .. capture_dir
        hs.alert.show(message)
        -- PRN reset to common spot?
        error(message)
    end

    if capture_sub_dir ~= nil then
        capture_dir = capture_dir .. "/" .. capture_sub_dir
        if not hs.fs.attributes(capture_dir) then
            print("creating capture_sub_dir", capture_dir)
            hs.fs.mkdir(capture_dir)
        end
    end

    local shortFileNamePath = capture_dir .. "/" .. filename .. "." .. extension
    print("trying filename", shortFileNamePath)
    if hs.fs.attributes(shortFileNamePath) == nil then
        return shortFileNamePath
    end

    -- add differentiation otherwise screencap will overwrite previous caps with same name
    --    2025-02-07 14h17m41s.450.png
    -- get fraction of second using absoluteTime such that .100 == 100ms
    local sub_second = (hs.timer.absoluteTime() / 1e6) % 1000

    -- TODO add appName, image_tag, etc here too, make it the same except for time as the above logic
    local longerPath = capture_dir
        .. "/" .. os.date("%Y-%m-%d %Hh%Mm%Ss")
        .. string.format("%3.0f", sub_second)

    if appName ~= nil then
        longerPath = longerPath .. "." .. appName
    end

    if image_tag ~= nil then
        longerPath = longerPath .. "." .. image_tag
    end

    return longerPath .. "." .. extension
end

-- normal keys:
--   shift+cmd+3 => full screen to file
--     ctrl      =>             to clipboard
--   shift+cmd+4 => selection/window to file
--     ctrl      =>             to clipboard
--   shift+cmd+5 => record video of screen (or opts for what?)
--
-- ideas:
--   open capture menu?
--   don't capture non-primary screen like macos default does which caps my blank lappy screen (super annoying)


hs.hotkey.bind({ "shift", "cmd" }, "3", function()
    local filename = get_screencapture_filename()
    -- PRN add "-m" if secondary screen is captured... right now it isn't so I don't need it (yet?)
    hs.task.new("/usr/sbin/screencapture", nil, { filename }):start()

    -- TODO quality level? any undocumented settings for that (look at binary for undocumented options)
    --    strings (which screencapture ) | grep "screencapture:" -A 10
    --      show-capture-rects
    --      showToolbarInInteractive
    --      captureOnlyEventRegion
    --      addResolutionMetadata
    --      windowsToCapture / uidWIDs
end)

hs.hotkey.bind({ "shift", "cmd", "ctrl" }, "2", function()
    hs.task.new("/opt/homebrew/bin/fish", nil, { "-c", "screencapture_ocr" }):start()
end)


hs.hotkey.bind({ "shift", "cmd", "ctrl" }, "3", function()
    hs.task.new("/usr/sbin/screencapture", nil, { "-c" }):start()
end)

hs.hotkey.bind({ "shift", "cmd" }, "4", function()
    local filename = get_screencapture_filename()
    -- FYI -J window => b/c I like window almost always when use region/interactive selection
    -- -o => don't capture shadow (and cannot use option to add it either, which is fine, use software to add it if needed)
    --   shadow adds 300KB+ to each image! good riddance
    hs.task.new("/usr/sbin/screencapture", nil, { "-i", "-o", "-J", "window", filename }):start()
end)

hs.hotkey.bind({ "shift", "cmd", "ctrl" }, "4", function()
    -- -c => clipboard
    hs.task.new("/usr/sbin/screencapture", nil, { "-ci", "-o", "-J", "window" }):start()
end)

hs.hotkey.bind({ "shift", "cmd" }, "5", function()
    -- !!! TODO check if currently running and STOP if so! that would rock

    -- TODO hrm... must need to be interactive to work? or can I pass a thing to show a toolbar or smth?
    --   or non-interactive can that only be when I set a fixed duration
    local filename = get_screencapture_filename("mp4")
    -- TODO defaults?
    --   TODO alt bindings for other combos (instead of ctrl to copy to clippy, or could I do that?)
    -- TODO `-G` and device id for MixPre6v2
    -- TODO -U... show toolbar in interactive
    hs.task.new("/usr/sbin/screencapture", nil, { "-vi", "-U", filename }):start()
end)

-- screencapture cmd:
-- -c      * Force screen capture to go to the clipboard.
-- -b      Capture Touch Bar, only works in non-interactive modes.
-- -C      Capture the cursor as well as the screen.  Only allowed in non-interactive modes.
-- -d      * Display errors to the user graphically.
--
-- -i      * Capture screen interactively, by selection or window.
--             The control key will cause the screenshot to go to the clipboard.
--             The space key will toggle between mouse selection and window selection modes.
--             The escape key will cancel the interactive screenshot.
--
-- -m      * Only capture the main monitor, undefined if -i is set.
-- -D      * <display> Screen capture or record from the display specified. 1 is main, 2 secondary, etc
-- -o      * In window capture mode, do not capture the shadow of the window.
--             FYI can just hold down option when take the screenshot to not take shadow too...
-- -p      Screen capture will use the default settings for capture. The files argument will be ignored.
-- -M      Open the taken picture in a new Mail message.
-- -P      Open the taken picture in a Preview window or QuickTime Player if video.
-- -I      Open the taken picture in Messages.
-- -B      <bundleid> Open in the app matching bundleid.
-- -s      * Only allow mouse selection mode.
-- -S      In window capture mode, capture the screen instead of the window.
-- -J      * <style> Sets the starting style of interfactive capture:
--                     "selection","window","video"
-- -t      ** <format> Image format to create, default is png:
--                     (other options include pdf, jpg, tiff and other formats).
-- -T      *** <seconds> Take the picture after a delay of <seconds>, default is 5.
--
-- -w      * Only allow window selection mode.
-- -W      * Start interaction in window selection mode.
--
-- -x      * Do not play sounds.
-- -a      Do not capture attached windows.
-- -r      Do not add screen dpi meta data to captured file.
-- -l      <windowid> Captures the window with windowid.
-- -R      ** <rectangle> Capture rectangle using format x,y,width,height.
--
-- -v      * Capture video recording of the screen.
-- -V      <seconds> Capture video recording of the screen for the specified seconds.
--
-- -G      ** <id> Captures audio during a video recording using audio source specified by id.
-- -g      Captures audio during a video recording using default input.
--
-- -k      Show clicks in video recordings.
-- -U      Show interactive toolbar in interactive mode.
-- -u      ? Present UI after screencapture is complete. Files passed to commandline will be ignored.
--
-- files   ** where to save the screen capture, 1 file per screen
--
-- FYI can take screencap over SSH with:
--   To capture screen content while logged in via ssh, you must launch screencapture in the same mach bootstrap hierarchy as loginwindow:
--     PID=pid of loginwindow
--     sudo launchctl bsexec $PID screencapture [options]
