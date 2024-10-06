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

# fishtape fish/functions/is_empty.fish
@test "is_empty with nothing" (is_empty) $status -eq 0
@test "is_empty with empty string" (is_empty "") $status -eq 0
@test "is_empty with something" (is_empty "something") $status -eq 1