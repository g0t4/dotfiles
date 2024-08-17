use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

on joinStringsWithNewLine(theList)
	set originalDelimiters to (get AppleScript's text item delimiters)
	set AppleScript's text item delimiters to return
	set joinedString to theList as text
	set AppleScript's text item delimiters to originalDelimiters
	return joinedString
end joinStringsWithNewLine

on splitStringOnNewline(theString)
	set text item delimiters to return
	set theList to every text item of theString
	set text item delimiters to ""
	return theList
end splitStringOnNewline


on readProfileUrls(profile_name)
	-- todo failure logic? currently empty file = no urls (empty string) which is probably ok for now cuz then I can do nothing to restore them
	set filePath to "~/.config/restorable-profiles/" & profile_name & ".urls"
	set urls to do shell script "cat " & filePath
	return splitStringOnNewline(urls)
end readProfileUrls

tell application "Brave Browser Beta"

	set urls to my readProfileUrls("haskell")

	if urls = {} then
		return
	end if

	set firstUrl to item 1 of urls
	set newWindow to make new window
	set URL of active tab of newWindow to firstUrl

	-- would be nice to save tab groups too but I can survive for now me thinks

	-- LOOP over rest of urls, 2+
	tell newWindow
		repeat with i from 2 to (count of urls)
			set theUrl to item i of urls
			make new tab with properties {URL:theUrl}
		end repeat

	end tell
end tell



