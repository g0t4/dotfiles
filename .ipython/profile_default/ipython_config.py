c = get_config()  #noqa

# FYI I setup a second profile and left all defaults in it, that way this file is not bloated but I also have a reference
#   ipython profile create foo-lookup-defaults
#   cat ~/.ipython/profile_foo-lookup-defaults/ipython_config.py | grep -i foo

c.TerminalInteractiveShell.confirm_exit = False

# turn off that banner w/ version info when first open REPL (i.e. in nvim)
c.TerminalIPythonApp.display_banner = False
