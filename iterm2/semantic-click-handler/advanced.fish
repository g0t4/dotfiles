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
#   $HOME/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/semantic-click-handler/advanced.fish \1 "\2" "unused" "unused" \5
#       \1,\5 => iTerm escapes "\ " the paths, so I don't need "", AND if I add "" then logic below sees them as "\ " not " " and then fails (ie test if directory)
#           PRN if I have further issues with escaping, I should look in iTerm2 source/docs for how it interpolates...
#       \2 => leave "\2" because if there is no line number then the blank means the args shift left (\3 => \2, \4 => \3, etc)
#       \3 \4 => unused => not using \3 \4 and I had an old note about them causing issues so I replaced with "unused" so the other args stay in the same position
#

function call_code
    if test -x /opt/homebrew/bin/code
        set vscode /opt/homebrew/bin/code
    else if test -x /usr/local/bin/code
        set vscode /usr/local/bin/code
    else
        echo "[FATAL] cannot find code command, aborting..."
        exit 1
    end

    $vscode $argv # call code with all args passed to this func
end

## TROUBLESHOOTING (iterm2 shows output on a failure, so add a failure to inspect these values)
for i in (seq 1 6)
    echo "[DEBUG] arg $i: $argv[$i]"
end

set clicked_path $argv[1] # dir or file, must exist if iTerm2 allowed to click open it
set line_number $argv[2]
set text_before_click $argv[3]
set text_after_click $argv[4]
set working_directory $argv[5]

if test -d "$clicked_path"
    # if clicked path is a directory...
    open "$clicked_path" # open dir in Finder (default handler)
    # call_code "$clicked_path" # open dir in vscode
    exit 0
end

# TODO detect some file types and open via regular handlers?
# # USE file command to decide if I want to use default handlers to open (or specific handler) 
set _mime_type (file --brief --mime-type "$clicked_path")
echo "[DEBUG]: mime type: $_mime_type"
#
if string match --quiet "$_mime_type" application/pdf
    # find test cases:     ag -ig "pdf\$"
    open "$clicked_path" # open w/ default handler
    exit 0
end

if string match --quiet --regex "image/.*" "$_mime_type"
    # find test cases:     ag -ig "jpg|gif|png"
    open "$clicked_path" # open w/ default handler
    # PRN open w/ vscode instead? I don't really mind that aside from issues with svgs
    exit 0
end

# scope vscoded to the repo root, else working directory if not a repo
if git rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null
    set vscode_scope_dir (git rev-parse --show-toplevel "$working_directory" 2>/dev/null)
else
    set vscode_scope_dir "$working_directory"
end

call_code \
    --goto "$clicked_path:$line_number" \
    "$vscode_scope_dir"

exit 0
