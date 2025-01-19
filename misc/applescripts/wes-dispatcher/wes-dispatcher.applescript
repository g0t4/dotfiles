on run args
	
	
	-- TODO permission issues writing to disk and notifications once its in an app format
	-- good test if you know current dir
	-- do shell script "touch fooboodoo"
	
	-- do shell script "/opt/homebrew/bin/fish ~/repos/github/g0t4/dotfiles/iterm2/semantic-click-handler/alfred-open-with-nvim.fish "$@" >> ~/.config/wes-dispatcher.log"
	do shell script "/opt/homebrew/bin/fish ~/repos/github/g0t4/dotfiles/iterm2/semantic-click-handler/alfred-open-with-nvim.fish \"" & args & "\""
	
	
	return
	
	-- FYI in Script Debugger, 
	-- FYI cannot set args to {file1,file2} explicitly b/c then wont run in Script Debugger/Editor... 
	--   but if use just `args` then it will work, make sure to check for no args too else (args as string) below will fail too
	if (class of args) is script then
		log "script passed, that happens in Script Debugger when you run a script with an explicit run handler defined, with args defined too"
		display dialog "you appear to be running in Script Debugger/Editor, use the CLI instead to test this so you can control the args that are passed"
		-- TODO wire up dispatch for a static file path like:
		--     ~/repos/github/g0t4/dotfiles/README.md 
	else if class of args is list then
		log "passed files: " & (args as string)
		-- TODO fix for passing multiple files (they get smooshed in (args as string) into one arg)
		if (count of args) is 0 then
			display dialog "you did not provide a file to open"
			return
		end if
		-- TODO launch nvim.fish or w/e it was
	else
		display dialog "it appears you did not pass any args, you must provide a file to open (dispatch)"
	end if
end run


-- testing:
--
-- osascript wes-dispatcher-new.applescript  $HOME/repos/github/g0t4/dotfiles/README.md 
--
-- compile to app:
--   osacompile -o wes.app wes-dispatcher-new.applescript