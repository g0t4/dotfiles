use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

tell application "iTerm"
	activate

	-- create window with default profile
	create window with profile "WesLearning"

	tell the first window

		tell current session

			-- TODO reuse this for diff profiles? wait until I have a need to do that and address it then

			write text "z learn-category-theory/haskell"
			write text "code (_repo_root)"
			delay 0.1
			write text "ghci" -- OPEN python REPL
			delay 0.1 -- delay so Cmd+K works next

			-- PRN (use iTerm's python API, IIAC)
			-- invoke API expression
			-- launch API script named (this makes more sense if I need things applescript cannot do directly or easily)

		end tell

		tell application "System Events"
			keystroke "k" using {command down}
			-- PRN split panes, new tabs, etc
			(*
				tell process "iTerm2"
					-- use this if not using custom profile (i.e. on my default recording profile)
					click menu item "Make Text Smaller" of menu "View" of menu bar 1
					click menu item "Make Text Smaller" of menu "View" of menu bar 1
					click menu item "Make Text Smaller" of menu "View" of menu bar 1
					click menu item "Make Text Smaller" of menu "View" of menu bar 1
				end tell
			*)
		end tell
	end tell
end tell
