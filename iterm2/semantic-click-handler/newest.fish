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
#    $HOME/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/semantic-click-handler/newest.fish "\1" "\2" "\3" "\4" "\5"
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

set filename $argv[1]
set line_number $argv[2]
set text_before_click $argv[3]
set text_after_click $argv[4]
set working_directory $argv[5]


# open vscode scoped to the repo root directory
set repo_root (git rev-parse --show-toplevel $working_directory)
call_code \
    --goto $filename:$line_number \
    $repo_root

exit
