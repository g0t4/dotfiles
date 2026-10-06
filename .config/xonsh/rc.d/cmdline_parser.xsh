import ast
import rich
from xonsh.built_ins import XSH

BOLD_RED = "\x1b[1;31m"
RESET = "\x1b[0m"

def _is_subprocess_run(node):
    if not isinstance(node, ast.Call):
        return False
    f = node.func
    rich.print(f"{f=}")
    if isinstance(f, ast.Attribute):
        return (
            isinstance(f.value, ast.Name)
            and f.value.id == "subprocess"
            and f.attr == "run"
        )
    return False

def _is_subproc_call(node):
    """True if node is an xonsh subprocess-mode call (__xonsh__.subproc_*)."""
    if not isinstance(node, ast.Call):
        return False
    f = node.func
    if isinstance(f, ast.Attribute):
        return (
            isinstance(f.value, ast.Name)
            and f.value.id == "__xonsh__"
            and f.attr.startswith("subproc")
        )
    if isinstance(f, ast.Name):
        return f.id.startswith("subproc")
    return False

def print_ast_code(src, tree=None, ctx=None):
    """Unparse the AST and bold-red any subprocess calls."""
    global _tree
    if tree is None:
        tree = XSH.execer.parse(src, ctx if ctx is not None else XSH.ctx,
                                transform=True)
    _tree = tree

    code = ast.unparse(tree)

    # Collect subprocess calls in source order (outer before inner).
    # calls = [n for n in ast.walk(tree) if _is_subproc_call(n)]
    calls = [n for n in ast.walk(tree) if _is_subprocess_run(n)]
    calls.sort(key=lambda n: (n.lineno, n.col_offset))

    out, pos = [], 0
    for node in calls:
        seg = ast.unparse(node)          # e.g. __xonsh__.subproc_uncaptured(['ls', '-l'])
        idx = code.find(seg, pos)
        if idx == -1:
            continue
        out.append(code[pos:idx])
        out.append(BOLD_RED + seg + RESET)
        pos = idx + len(seg)
    out.append(code[pos:])
    print("".join(out))

def _offset(src, lineno, col):
    """Convert a 1-based lineno / 0-based col into an absolute char offset."""
    lines = src.splitlines(keepends=True)
    print(f"{lineno=}")
    return sum(len(l) for l in lines[:lineno - 1]) + col

def _dump(node):
    import rich
    # print(ast.dump(node, indent=True, annotate_fields=True, include_attributes=True))
    # print(ast.dump(node, indent=True, annotate_fields=True))
    print(ast.dump(node, indent=True))

def _collect_spans(tree, src):
    spans = []
    for node in ast.walk(tree):
        print(hasattr(node, "end_lineno"), getattr(node, "end_lineno", "NO FUCKING EL"))
        # if _is_subproc_call(node) and hasattr(node, "end_lineno"):
        if _is_subprocess_run(node) and hasattr(node, "end_lineno"):
            _dump(node)
            start = _offset(src, node.lineno, node.col_offset)
            end = _offset(src, node.end_lineno or , node.end_col_offset)
            spans.append((start, end))
    return spans

def _merge(spans):
    """Collapse overlapping/contained spans (e.g. nested command substitution)."""
    spans.sort()
    merged = []
    for s, e in spans:
        if merged and s <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], e))
        else:
            merged.append((s, e))
    return merged

