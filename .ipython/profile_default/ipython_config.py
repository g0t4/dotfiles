c = get_config()  #noqa

# FYI I setup a second profile and left all defaults in it, that way this file is not bloated but I also have a reference
#   ipython profile create foo-lookup-defaults
#   cat ~/.ipython/profile_foo-lookup-defaults/ipython_config.py | grep -i foo

c.TerminalInteractiveShell.confirm_exit = False

# https://github.com/asteppke/ipython/blob/000929ad8c4893d7fb73bee9c431352383dfce6f/IPython/terminal/interactiveshell.py#L320
c.TerminalInteractiveShell.autosuggestions_provider = None

# turn off that banner w/ version info when first open REPL (i.e. in nvim)
c.TerminalIPythonApp.display_banner = False

# *** traceback color problem

# FYI the color scheme itself didn't change much, definitely didn't fix the issue with traceback highlight color contrast
## Set the color scheme (nocolor, neutral, linux, lightbg).
#  Default: 'neutral'
# c.InteractiveShell.colors = 'linux' # better colors for python stack traces but still terrible contrast
#
## Set the color scheme (nocolor, neutral, linux, lightbg).
#  See also: InteractiveShell.colors
# c.TerminalInteractiveShell.colors = 'neutral'

# this makes traceback highlights legible:
from IPython.core.ultratb import VerboseTB

VerboseTB.tb_highlight = "bg:ansiyellow ansiblack"  # I like the yellow, just want black text

# * change keymaps
c.TerminalInteractiveShell.shortcuts = [
    {
        # change how ctrl+w treats word boundary chars... somehow this triggers it to respect . (dot) as a word separator
        # test this with:
        #  import foo.bar<Ctrl-W>
        #  now it should stop on . (not wipe out entire module name)
        "new_keys": ["c-w"],
        "command": "prompt_toolkit:named_commands.backward_kill_word",
        "create": True,
    }
]

#  - IPython:shortcuts.handle_return_or_newline_or_execute
#  - IPython:shortcuts.reformat_and_execute
#  - IPython:shortcuts.quit
#  - IPython:shortcuts.previous_history_or_previous_completion
#  - IPython:shortcuts.next_history_or_next_completion
#  - IPython:shortcuts.dismiss_completion
#  - IPython:shortcuts.reset_buffer
#  - IPython:shortcuts.reset_search_buffer
#  - IPython:shortcuts.suspend_to_bg
#  - IPython:shortcuts.indent_buffer
#  - IPython:shortcuts.newline_autoindent
#  - IPython:shortcuts.open_input_in_editor
#  - IPython:auto_match.parenthesis
#  - IPython:auto_match.brackets
#  - IPython:auto_match.braces
#  - IPython:auto_match.raw_string_parenthesis
#  - IPython:auto_match.raw_string_bracket
#  - IPython:auto_match.raw_string_braces
#  - IPython:auto_match.double_quote
#  - IPython:auto_match.single_quote
#  - IPython:auto_match.docstring_double_quotes
#  - IPython:auto_match.docstring_single_quotes
#  - IPython:auto_match.skip_over
#  - IPython:auto_match.delete_pair
#  - IPython:auto_suggest.accept_or_jump_to_end
#  - IPython:auto_suggest.accept
#  - IPython:auto_suggest.accept_word
#  - IPython:auto_suggest.accept_token
#  - IPython:auto_suggest.discard
#  - IPython:auto_suggest.swap_autosuggestion_up
#  - IPython:auto_suggest.swap_autosuggestion_down
#  - IPython:auto_suggest.up_and_update_hint
#  - IPython:auto_suggest.down_and_update_hint
#  - IPython:auto_suggest.accept_character
#  - IPython:auto_suggest.accept_and_move_cursor_left
#  - IPython:auto_suggest.accept_and_keep_cursor
#  - IPython:auto_suggest.backspace_and_resume_hint
#  - IPython:auto_suggest.resume_hinting
#  - prompt_toolkit:completion.display_completions_like_readline
#  - IPython:shortcuts.win_paste
#  - prompt_toolkit:named_commands.beginning_of_line
#  - prompt_toolkit:named_commands.backward_char
#  - prompt_toolkit:named_commands.kill_line
#  - prompt_toolkit:named_commands.backward_kill_word
#  - prompt_toolkit:named_commands.yank
#  - prompt_toolkit:named_commands.undo
#  - prompt_toolkit:named_commands.edit_and_execute
#  - prompt_toolkit:named_commands.backward_word
#  - prompt_toolkit:named_commands.capitalize_word
#  - prompt_toolkit:named_commands.kill_word
#  - prompt_toolkit:named_commands.downcase_word
#  - prompt_toolkit:named_commands.uppercase_word
#  - prompt_toolkit:named_commands.yank_pop
#  - prompt_toolkit:named_commands.yank_last_arg
#
