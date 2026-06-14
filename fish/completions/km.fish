# Keyboard Maestro CLI completions

# Options
complete -c km -s a -l async -d "Run asynchronously (don't wait for completion)"
complete -c km -s e -l edit -d "Edit mode (open in editor instead of running)"
complete -c km -s h -l help -d "Show usage information"
complete -c km -s p -l parameter -d "Pass value as the parameter to macro" -r -x
complete -c km -s v -l verbose -d "Verbose output"
complete -c km -s V -l version -d "Show version"

# --list flag
complete -c km -l list -d "List all macros (UUID|Name format)"

# Macro name/UUID autocompletion (only when not using flags)
function _km_get_macro_list
    osascript -e 'tell application "Keyboard Maestro" to return id of every macro & "|" & name of every macro' 2>/dev/null | string split "," | string trim | string replace '|' '\t'
end

complete -c km -a '(_km_get_macro_list)' -f -d "Keyboard Maestro macro"
