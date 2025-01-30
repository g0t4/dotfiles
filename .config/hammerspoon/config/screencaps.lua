function getScreencaptureFileName()
    local app = hs.application.frontmostApplication()
    local appElement = hs.axuielement.applicationElement(app)

    -- TODO what do I want for filename? how about capture frontmost app's frontmost window name?
    local filename = os.date("%Y-%m-%d_%I-%M-%S-%p_Screenshot.png")
    local snapshots_dir = os.getenv("HOME") .. "/Pictures/Screencaps"
    local filePath = snapshots_dir .. "/" .. filename
    return filePath
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
    local filename = getScreencaptureFileName()
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

hs.hotkey.bind({ "shift", "cmd", "ctrl" }, "3", function()
    hs.task.new("/usr/sbin/screencapture", nil, { "-c" }):start()
end)

hs.hotkey.bind({ "shift", "cmd" }, "4", function()
    local filename = getScreencaptureFileName()
    hs.task.new("/usr/sbin/screencapture", nil, { "-i", filename }):start()
end)

hs.hotkey.bind({ "shift", "cmd", "ctrl" }, "4", function()
    hs.task.new("/usr/sbin/screencapture", nil, { "-ci" }):start()
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
-- -m      *** Only capture the main monitor, undefined if -i is set.
-- -D      <display> Screen capture or record from the display specified. 1 is main, 2 secondary, etc
-- -o      *** In window capture mode, do not capture the shadow of the window.
-- -p      Screen capture will use the default settings for capture. The files argument will be ignored.
-- -M      Open the taken picture in a new Mail message.
-- -P      Open the taken picture in a Preview window or QuickTime Player if video.
-- -I      Open the taken picture in Messages.
-- -B      <bundleid> Open in the app matching bundleid.
-- -s      * Only allow mouse selection mode.
-- -S      In window capture mode, capture the screen instead of the window.
-- -J      * <style> Sets the starting style of interfactive capture "selection","window","video".
-- -t      ** <format> Image format to create, default is png (other options include pdf, jpg, tiff and other formats).
-- -T      *** <seconds> Take the picture after a delay of <seconds>, default is 5.
--
-- -w      *** Only allow window selection mode.
-- -W      *** Start interaction in window selection mode.
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
