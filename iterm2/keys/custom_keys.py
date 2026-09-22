import iterm2

PUA_BASE = 0xE000

MOD_BITS = {
    "shift": 1 << 0,
    "ctrl":  1 << 1,
    "alt":   1 << 2,
    "cmd":   1 << 3,
}

ITERM_MODIFIERS = {
    "shift": iterm2.Modifier.SHIFT,
    "ctrl":  iterm2.Modifier.CONTROL,
    "alt":   iterm2.Modifier.OPTION,
    "cmd":   iterm2.Modifier.COMMAND,
}

CUSTOM_KEYS = {
    "cmd+j",
    # "cmd+k",
    "cmd+l",

    "cmd+shift+j",
    "cmd+shift+k",
    "cmd+shift+l",

    "cmd+ctrl+k",
}


def parse_chord(chord):
    parts = chord.lower().split("+")
    key = parts[-1]
    modifier_names = parts[:-1]

    if len(key) != 1:
        raise ValueError(f"Unsupported key: {key!r}")

    modifiers = [ITERM_MODIFIERS[name] for name in modifier_names]
    modifier_mask = sum(MOD_BITS[name] for name in modifier_names)

    return key, modifiers, modifier_mask


# Stable physical-key IDs. Add keys here without changing existing IDs.
KEY_IDS = {
    chr(ord("a") + i): i
    for i in range(26)
}


def make_binding(chord):
    key, modifiers, modifier_mask = parse_chord(chord)
    key_id = KEY_IDS[key]

    cp = PUA_BASE + (key_id << 4) + modifier_mask
    payload = chr(cp).encode("utf-8").hex(" ")

    return iterm2.KeyBinding(
        character=ord(key),
        modifiers=modifiers,
        keycode=None,
        action=iterm2.BindingAction.HEX_CODE,
        param=payload,
        version=None,
        label=None,
    )


def same_chord(a, b):
    return (
        a.character == b.character
        and set(a.modifiers) == set(b.modifiers)
        and a.keycode == b.keycode
    )

def is_ours(binding):
    if binding.action != iterm2.BindingAction.HEX_CODE:
        return False

    try:
        raw = bytes.fromhex(binding.param)
        text = raw.decode("utf-8")
    except (ValueError, UnicodeDecodeError):
        return False

    return (
        len(text) == 1
        and 0xE000 <= ord(text) <= 0xF8FF
    )

async def install_custom_keys(connection):
    existing = list(
        await iterm2.async_get_global_key_bindings(connection)
    )

    for chord in sorted(CUSTOM_KEYS):
        new = make_binding(chord)

        old = next(
            (x for x in existing if same_chord(x, new)),
            None,
        )

        if old is None:
            existing.append(new)
            print(f"ADD     {chord:20} {new.param}")
            continue

        if not is_ours(old):
            print(
                f"SKIP    {chord:20} existing non-managed binding: "
                f"{old.action} {old.param!r}"
            )
            continue

        existing[existing.index(old)] = new

        if old == new:
            print(f"KEEP    {chord:20} {new.param}")
        else:
            print(f"UPDATE  {chord:20} {old.param} -> {new.param}")

    await iterm2.async_set_global_key_bindings(connection, existing)
