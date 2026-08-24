"""Current-shell recording modes mirrored from Fish's always/always.fish."""


def _always_set_ai_autosuggest(enabled):
    ${...}["XONSH_AI_AUTOSUGGEST"] = enabled

    # A recording-mode change can happen while a prediction is streaming.
    # Cancel it immediately instead of waiting for another buffer edit.
    autosuggester = globals().get("_ai_autosuggester")
    if autosuggester is not None:
        active_task = autosuggester._active_task
        if not enabled and active_task is not None and not active_task.done():
            active_task.cancel()

    logger = globals().get("_ai_log")
    if logger is not None:
        logger.info("recording_mode_autosuggest enabled=%s", enabled)


def _always_recording(_args, **_):
    _always_set_ai_autosuggest(False)
    return 0


def _always_not_recording(_args, **_):
    _always_set_ai_autosuggest(True)
    return 0


def _always_shorts(_args, **_):
    ${...}["wes_recording_youtube_shorts_need_small_prompt"] = True
    return 0


def _always_not_shorts(_args, **_):
    ${...}.pop("wes_recording_youtube_shorts_need_small_prompt", None)
    return 0


aliases["_recording"] = _always_recording
aliases["_not_recording"] = _always_not_recording
aliases["_shorts"] = _always_shorts
aliases["_not_shorts"] = _always_not_shorts
