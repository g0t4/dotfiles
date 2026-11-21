"""Let the prompt layout request rows as needed."""

from xonsh.built_ins import XSH
from xonsh.events import events
from xonsh.tools import to_bool


XSH.env.register(
    "WES_XONSH_COMPACT_PROMPT",
    type="bool",
    default=True,
    doc="Avoid filling idle prompt space with blank lines before a pane resize.",
)


@events.on_ptk_create
def _wes_compact_prompt(prompter, **_):
    renderer = prompter.app.renderer
    render = renderer.render

    def render_compact(app, layout, is_done=False):
        compact = to_bool(XSH.env["WES_XONSH_COMPACT_PROMPT"])
        if not compact or prompter.bottom_toolbar is not None:
            return render(app, layout, is_done=is_done)

        # PTK uses the cursor report as a minimum render height and writes
        # newlines to fill it. Keep the report for mouse coordinates and let
        # the layout choose the height for this render, including Tab menus.
        reported_height = renderer._min_available_height
        renderer._min_available_height = min(reported_height, 1)
        try:
            return render(app, layout, is_done=is_done)
        finally:
            renderer._min_available_height = reported_height

    renderer.render = render_compact
