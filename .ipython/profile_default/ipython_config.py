c = get_config()  #noqa

c.TerminalInteractiveShell.confirm_exit = False

# turn off that banner w/ version info when first open REPL (i.e. in nvim)
c.TerminalIPythonApp.display_banner = False
