#!/opt/homebrew/bin/fish

# *** docs from iterm2 prefs => profile => advanced tab => semantic history ***
# In this mode semantic history will only be activated when you click on an existing file name.
# You can provide substitutions as follows:
#   \1 will be replaced with the filename.
#   \2 will be replaced with the line number.
#   \3 will be replaced with the text before the click.
#   \4 will be replaced with the text after the click.
#   \5 will be replaced with the working directory.
#
# This is also an interpolated string evaluated in the context of the current session. In addition to the usual variables, the following substitutions are available:
#   \(semanticHistory.path) will be replaced with the filename.
#   \(semanticHistory.lineNumber) will be replaced with the line number.
#   \(semanticHistory.columnNumber) will be replaced with the column number.
#   \(semanticHistory.prefix) will be replaced with the text before the click.
#   \(semanticHistory.suffix) will be replaced with the text after the click.
#   \(semanticHistory.workingDirectory) will be replaced with the working directory.
# *** end docs ***
#
# *** FYI I used this value in iterm2 semantic history text box:
#   set drop down to "Run command"
#      TODO try "Always run command" which can work with text that is not an existing file => i.e. parse text for things like github "org/repo" in output, and open in browser at github.com?
#   $HOME/repos/github/g0t4/dotfiles/iterm2/semantic-click-handler/advanced.fish \1 "\2" "unused" "unused" \5
#       \1,\5 => iTerm escapes "\ " the paths, so I don't need "", AND if I add "" then logic below sees them as "\ " not " " and then fails (ie test if directory)
#           PRN if I have further issues with escaping, I should look in iTerm2 source/docs for how it interpolates...
#       \2 => leave "\2" because if there is no line number then the blank means the args shift left (\3 => \2, \4 => \3, etc)
#       \3 \4 => unused => not using \3 \4 and I had an old note about them causing issues so I replaced with "unused" so the other args stay in the same position
#

## TROUBLESHOOTING (iterm2 shows output on a failure, so add a failure to inspect these values)
for i in (seq 1 6)
    echo "[DEBUG] arg $i: $argv[$i]"
end

set clicked_path $argv[1] # dir or file, must exist if iTerm2 allowed to click open it
set line_number $argv[2]
set text_before_click $argv[3]
set text_after_click $argv[4]
set working_directory $argv[5]

set alfred_open_with $argv[6]

# *** handle directory clicks ***
if test -d "$clicked_path"
    if not test "$alfred_open_with" = alfred-open-with
        # if clicked path is a directory...
        open "$clicked_path" # open dir in Finder (default handler)
        # call_code "$clicked_path" # open dir in vscode
        exit 0
    end
end

# # USE file command to decide if I want to use default handlers to open (or specific handler)
set _mime_type (file --brief --mime-type "$clicked_path")
echo "[DEBUG]: mime type: $_mime_type"

if string match --quiet --regex "\.car\$" "$clicked_path"
    # TODO other image types
    open "$clicked_path" # open w/ default handler
    exit 0
end

# PRN perhaps re-workt his to just use defaults in macOS (i.e. open, except when I wanna override what open would do... why have second hierarchy here?)

# * pdfs, msft office
if string match --quiet application/pdf "$_mime_type"
    or string match --regex --quiet "vnd.openxmlformats-officedocument" "$_mime_type"
    open "$clicked_path" # open w/ default handler
    exit 0
end

# *** images ***
if string match --quiet --regex "image/.*" "$_mime_type"
    # not svgs, those open in default app (i.e. nvim)
    and not string match --quiet "$_mime_type" image/svg+xml

    # find test cases:     ag -ig "jpg|gif|png"
    # CAREFUL NOT TO GET STUCK IN LOOP, I use automator to call this for Open in Neovim in Finder... and if this uses Open directly it might just loop recursively forever
    # that's when you have to `sudo pkill -ilf Automator` to stop the ScriptMonitor failure dialogs
    open -a Preview "$clicked_path" # open w/ default handler
    # PRN open w/ vscode instead? I don't really mind that aside from issues with svgs
    exit 0
end

# *** default => vscode ***
# scope vscode to the repo root, else working directory if not a repo
set workspace_root $(git -C $working_directory rev-parse --show-toplevel 2>/dev/null)
if test $status -ne 0
    set workspace_root $working_directory
end

# cd to dir for two reasons:
#    1. so uv run finds venv
#    2. relative path for nvim.py
cd $WES_DOTFILES/iterm2/semantic-click-handler
uv run nvim.py \
    "$clicked_path" "$line_number" "$text_before_click" \
    "$text_after_click" "$working_directory" "$workspace_root"
if test $status -ne 0
    # return non-zero so I can trigger failure in nvim.py alone and not need to set exit code here to get iterm to show the handler's debug output
    # don't need a message, that would come from nvim.py
    exit 1
end

#exit 1 # if you wanna see debug STDOUT messages above, uncomment this line and click "View" in the iTerm2 dialog
osascript -e 'tell application "iTerm" to activate'
