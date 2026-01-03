# I hate using `if test -n/z` to check for empty strings vs not-empty strings... so lets add a helper function that reads nicely when used in an `if` statement

function is_empty \
    --argument what \
    --description "use instead of test -z/n!"
    if string length --quiet -- $what
        return 1 # Not empty, return false in terms of emptiness
    else
        return 0 # Empty, return true in terms of emptiness
    end
end
