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
		tell application "System Events" to tell process "Finder"
			set frontmost to true
			key code 124 -- Right arrow
		end tell
		delay 0.2 -- Allow the disclosure animation to finish
	end if

	-- Match Finder's naming convention without colliding with an existing item.
	set newFolderName to "untitled folder"
	set suffix to 2
	repeat while exists item newFolderName of selectedDir
		set newFolderName to "untitled folder " & suffix
		set suffix to suffix + 1
	end repeat
	set newFolder to make new folder at selectedDir with properties {name:newFolderName}

	-- Finder refreshes the expanded list asynchronously after creating an item.
	-- Retry selection until it sticks, without using `select` (which can open a tab).
	set newFolderAlias to newFolder as alias
	set folderSelected to false
	repeat 30 times
		delay 0.1
		set selection to {newFolderAlias}
		delay 0.1
		set currentSelection to selection as alias list
		if (count of currentSelection) is 1 then
			if item 1 of currentSelection is newFolderAlias then
				set folderSelected to true
				exit repeat
			end if
		end if
	end repeat
	if not folderSelected then error "Finder did not select the new folder for renaming."
end tell

-- Give the confirmed selection time to render before sending Return.
delay 0.2
tell application "System Events" to tell process "Finder"
	set frontmost to true
	key code 36 -- Return: rename the selected folder
end tell
