"""Current-shell recording modes mirrored from Fish's always/always.fish."""

from wes_logging import get_logger


_always_log = get_logger("always")
_always_ai_autosuggest_before_recording = None


def _always_set_ai_autosuggest(enabled):
    @.env["XONSH_AI_AUTOSUGGEST"] = enabled

    # A recording-mode change can happen while a prediction is streaming.
    # Cancel it immediately instead of waiting for another buffer edit.
    autosuggester = globals().get("_ai_autosuggester")
    if autosuggester is not None:
        active_task = autosuggester._active_task
        if not enabled and active_task is not None and not active_task.done():
            active_task.cancel()

    _always_log.info("recording_mode_autosuggest enabled=%s", enabled)


def _always_recording(_args, **_):
    global _always_ai_autosuggest_before_recording
    if _always_ai_autosuggest_before_recording is None:
        _always_ai_autosuggest_before_recording = bool(
            @.env.get("XONSH_AI_AUTOSUGGEST", True)
        )
    _always_set_ai_autosuggest(False)
    return 0


def _always_not_recording(_args, **_):
    global _always_ai_autosuggest_before_recording
    enabled = (
        bool(@.env.get("XONSH_AI_AUTOSUGGEST", True))
        if _always_ai_autosuggest_before_recording is None
        else _always_ai_autosuggest_before_recording
    )
    _always_ai_autosuggest_before_recording = None
    _always_set_ai_autosuggest(enabled)
    return 0


def _always_shorts(_args, **_):
    @.env["wes_recording_youtube_shorts_need_small_prompt"] = True
    return 0


def _always_not_shorts(_args, **_):
    @.env.pop("wes_recording_youtube_shorts_need_small_prompt", None)
    return 0


aliases["_recording"] = _always_recording
aliases["_not_recording"] = _always_not_recording
aliases["_shorts"] = _always_shorts
aliases["_not_shorts"] = _always_not_shorts
