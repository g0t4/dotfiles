"""Show and insert call parentheses for Python callable completions."""

from xonsh.built_ins import XSH
from wes_python_call_completions import wrap_python_call_completions

# ``base`` supplies Python names alongside commands at the start of a line;
# ``python`` handles Python expressions elsewhere. Wrap both so their normal
# candidates, filtering, and command ordering remain in place.
for _name in ("base", "python"):
    XSH.completers[_name] = wrap_python_call_completions(XSH.completers[_name])
