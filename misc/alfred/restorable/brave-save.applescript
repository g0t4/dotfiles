use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

on joinStringsWithNewLine(theList)
	set originalDelimiters to (get AppleScript's text item delimiters)
	set AppleScript's text item delimiters to linefeed
	set joinedString to theList as text
	set AppleScript's text item delimiters to originalDelimiters
	return joinedString
end joinStringsWithNewLine

on splitStringOnNewline(theString)
	set text item delimiters to linefeed
	set theList to every text item of theString
	set text item delimiters to ""
	return theList
end splitStringOnNewline

on saveProfileUrls(profile_name, tabURLs)
	-- ensure dir exists
	do shell script "mkdir -p ~/.config/restorable-profiles"

	set joinedLinks to my joinStringsWithNewLine(tabURLs)

	set filePath to "~/.config/restorable-profiles/" & profile_name & ".urls"
	do shell script "echo " & quoted form of joinedLinks & " > " & filePath

end saveProfileUrls

on run argv
	set {profile_name} to {item 1} of argv

	tell application "Brave Browser Beta"
		set tabURLs to {}
		repeat with t in (tabs of front window)
			set end of tabURLs to URL of t
		end repeat

		my saveProfileUrls(profile_name, tabURLs)
	end tell

end run
