#
# *** FUNCTIONS that cannot be wrapped (to call fish version)
# Primary examples:
# - reads/modifies current command line, i.e. via fish's commandline builtin
function _abbr_expand_rgu {
    # FYI not ported part:
    #     if command_line_after_cursor_is_not_an_option_dash
    #         echo rg -u
    #         return
    #     end
    echo rg -u '"%"'
}
