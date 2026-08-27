"""Human-friendly semantic grep trace viewer."""

from wes_rag_trace_viewer import main as _rag_trace_viewer


def _ragtrace(args, **_):
    return _rag_trace_viewer(args)


aliases["ragtrace"] = _ragtrace
