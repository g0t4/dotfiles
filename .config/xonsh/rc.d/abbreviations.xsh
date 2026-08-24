"""Fish-style visible command abbreviations for Xonsh."""


XONSH_ABBREVIATIONS = {
    "gst": "git status",
}


def _expand_command_abbreviation(buffer):
    document = buffer.document
    word = document.get_word_before_cursor(WORD=True)
    expansion = XONSH_ABBREVIATIONS.get(word)
    if expansion is None:
        return False

    before_word = document.text_before_cursor[: -len(word)]
    # Like a normal Fish abbreviation, expand only in command position. This
    # simple first example covers the start of a command and pipeline segments.
    command_prefix = before_word.rstrip()
    if command_prefix and not command_prefix.endswith(("|", ";", "&&", "||")):
        return False

    buffer.delete_before_cursor(count=len(word))
    buffer.insert_text(expansion)
    return True


@events.on_ptk_create
def _wes_abbreviation_keybindings(bindings, **_):
    @bindings.add(" ")
    def _expand_abbreviation_on_space(event):
        _expand_command_abbreviation(event.current_buffer)
        event.current_buffer.insert_text(" ")


# If Enter is pressed without a trailing delimiter, retain the command behavior
# even though there was no opportunity to visibly expand the buffer first.
aliases["gst"] = ["git", "status"]
