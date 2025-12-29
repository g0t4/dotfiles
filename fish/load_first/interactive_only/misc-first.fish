function reminder_abbr --wraps abbr
    # mark reminder abbrs explicitly instead of inconsistent comments
    abbr $argv
end

function reminder_abbr_remapped
    set -l old $argv[1]
    set -l new $argv[2]
    abbr $old "REMINDER: abbr '$old' is now '$new'."
end
