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
