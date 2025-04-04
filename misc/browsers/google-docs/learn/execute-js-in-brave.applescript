use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

tell application "Brave Browser Beta"
	set wins to every window
	set front_window to first window
	set target_tab to active tab of front_window

	set code to "window.alert('hello')"
	set code to "console.clear();"

	set result to execute target_tab javascript code
end tell

