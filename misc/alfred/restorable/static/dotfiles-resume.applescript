use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

on clear_screen()
	tell application "System Events"
		keystroke "k" using {command down}
	end tell
end clear_screen

tell application "iTerm"
	activate

	-- create window with default profile
	create window with profile "WesLearning"

	tell the first window

		tell current session

			-- TODO reuse this for diff profiles? wait until I have a need to do that and address it then

			write text "z subs/dotfiles"
			write text "code (_repo_root)"
			delay 0.1

		end tell

		my clear_screen()
	end tell
end tell
