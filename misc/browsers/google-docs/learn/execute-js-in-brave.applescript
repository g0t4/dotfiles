use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

(*
	tell application "System Events"
		set proc to application process "Brave Browser Beta"
	end tell
*)


tell application "Brave Browser Beta"
	set wins to every window

	-- AFAICT front window is always the first window (order switches as you cycle windows)
	set front_window to first window

	set active_tab to active tab of front_window

	set code to "window.alert(window.location)"
	--set code to "console.clear();"

	-- a ref to, just in case there's only one (active) tab
	set not_active_tab to a reference to (first tab of front_window whose id is not (id of active_tab))
	if not (exists not_active_tab) then
		log "no inactive tabs"
		return
	end if

	set result to execute not_active_tab javascript code

	--	set result to execute active_tab javascript code
end tell
