@test "is_empty with nothing" (is_empty) $status -eq 0
@test "is_empty with empty string" (is_empty "") $status -eq 0
@test "is_empty with something" (is_empty "something") $status -eq 1


# fishtape fish/functions/tests/is_empty.fish
