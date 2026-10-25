#!/usr/bin/osascript

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

tell application "Finder"
	-- Get the currently selected items in Finder
	set selectedItems to selection
	if (count of selectedItems) is not 1 then
		display dialog "Please select exactly one directory." buttons {"OK"} default button "OK"
		return
	end if
	
	set selectedDir to item 1 of selectedItems
	
	if class of selectedDir is not folder then
		display dialog "The selected item is not a folder." buttons {"OK"} default button "OK"
		return
	end if
	
	activate

	-- Expand the selected directory in list/tree view so its new child is visible.
	if current view of front window is list view then
		tell application "System Events" to key code 124 -- Right arrow
	end if

	-- Match Finder's naming convention without colliding with an existing item.
	set newFolderName to "untitled folder"
	set suffix to 2
	repeat while exists item newFolderName of selectedDir
		set newFolderName to "untitled folder " & suffix
		set suffix to suffix + 1
	end repeat
	set newFolder to make new folder at selectedDir with properties {name:newFolderName}

	-- Set the selection directly; `select newFolder` can open another tab/window.
	set selection to {newFolder}
end tell

-- Let Finder display the selection before starting inline rename.
delay 0.2
tell application "System Events" to tell process "Finder"
	set frontmost to true
	key code 36 -- Return: rename the selected folder
end tell
