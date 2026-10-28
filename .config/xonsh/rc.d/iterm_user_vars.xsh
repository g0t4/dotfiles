from xonsh.built_ins import XSH
from xonsh.events import events

# * load static values once (not every time handler fires)
# b/c these are relatively speaking expensive (in terms of prompt overhead)
etc_release = Path("/etc/os-release")
if etc_release.exists():
    ask_os = None
    for line in etc_release.read_text().splitlines():
        if line.startswith('ID='):
            ask_os = line.split('=', 1)[1].strip('"')
            break
else:
    import platform
    ask_os = platform.system()  # or use $(uname) like fish script does  # Darwin, Linux, etc

@events.on_pre_prompt
def set_iterm2_ask_vars():
    # run after every command finishes so we can reset if that command changed these variables (i.e. SSH => remote shell)
    # OR, just run on every prompt... same net effect + don't worry about iterm2 shell integration load order!

    # FYI this only needs checked one time but it's cheap to check every time
    # + this defers the check until latest possible moment instead of when this file first loads
    if not hasattr(XSH, "iterm2"):
        print(f"CRAP... XSH.iterm2 is missing... iterm2.xsh shell integation is missing or you need to load it BEFORE this handler fires (from {__file__=})")

    XSH.iterm2.set_user_var("ask_shell", "xonsh")
    XSH.iterm2.set_user_var("ask_os", ask_os)
