"""Current-shell recording modes mirrored from Fish's always/always.fish."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

# Recording macros invoke these hooks in any shell.
def _always_recording(_args, **_):
    return 0


def _always_shorts(_args, **_):
    @.env["wes_recording_youtube_shorts_need_small_prompt"] = True
    return 0


def _always_not_shorts(_args, **_):
    @.env.pop("wes_recording_youtube_shorts_need_small_prompt", None)
    return 0


aliases["_recording"] = _always_recording
aliases["_not_recording"] = _always_recording
aliases["_shorts"] = _always_shorts
aliases["_not_shorts"] = _always_not_shorts
