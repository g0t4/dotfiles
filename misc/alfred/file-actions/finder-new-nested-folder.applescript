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
	
	-- prompt for folder name
	set newFolderName to text returned of (display dialog "Enter the name for the new folder:" default answer "New Nested Folder")
	
	
	-- Create the new folder inside the selected directory
	set newFolder to make new folder at selectedDir with properties {name:newFolderName}
	
	-- -- unfortunately `select` opens a new tab with the new directory and that is not what I want, so just use prompt before create to name it
	-- select newFolder
end tell