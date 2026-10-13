"""Daily Python/Lua viewers; also safe to source again in a running REPL."""

import shutil
from xonsh.built_ins import XSH
from wes_interactive_cat import InteractiveCat
from wes_syntax_theme import ThemeBat

if bool(XSH.env.get("XONSH_INTERACTIVE", False)):
    _syntax_bat = ThemeBat(env=XSH.env)
    XSH.aliases["bat"] = _syntax_bat
    XSH.aliases["bat-stock"] = [shutil.which("bat") or shutil.which("batcat") or "bat"]
    XSH.aliases["cat"] = InteractiveCat(env=XSH.env, bat=_syntax_bat)
