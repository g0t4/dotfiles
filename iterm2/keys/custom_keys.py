import iterm2
import rich

from rich.table import Table

PUA_BASE = 0xE000
PUA_END = 0xEFFF

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

LOWER_ALPHA = {
    chr(number): number
    for number in
    [
        ord("a") + i
        for i in range(26)
    ]
}
# iterm2 when I manually set `shift+alt+i` => results in this mapping:
# BTW test with `showkey` => press alt+i, shift+alt+i
#    should NOT show `alt+i` which is what it will show for both w/o my hexcode iterm keymaps
#
#  * ipython3 list_iterm2_global_keys.py # shows values from manually settting
#
UPPER_ALPHA = {
    chr(number): number
    for number in
    [
        ord("A") + i
        for i in range(26)
    ]
}
KEY_IDS = {**LOWER_ALPHA, **UPPER_ALPHA}

CUSTOM_KEYS = {

    # alt is now alt! (not escape)
    # btw this means I can go back to eager escape in xonsh/fish/etc and not need to have to wait for escape to in insert to transition to normal mode

    "alt+i",       # │ alt+i       │ U+E084  │ ee 82 84 │
    "alt+shift+I", # │ alt+shift+i │ U+E085  │ ee 82 85 │
    # "alt+I",

    # maybes:

    # maybes:
    #
    # "cmd+j",
    # "cmd+l",
    #
    # "cmd+shift+j",
    # "cmd+shift+k",
    # "cmd+shift+l",
    #
    # "cmd+ctrl+k",
    # "cmd+ctrl+i",

}


def parse_chord(chord):
    parts = chord.split("+")
    key = parts[-1]
    modifier_names = parts[:-1]

    if key not in KEY_IDS:
        raise ValueError(f"Unsupported key: {key!r}")

    unknown = set(modifier_names) - MOD_BITS.keys()
    if unknown:
        raise ValueError(f"Unknown modifiers: {unknown}")

    modifiers = [ITERM_MODIFIERS[x] for x in modifier_names]
    modifier_mask = sum(MOD_BITS[x] for x in modifier_names)

    return key, modifiers, modifier_mask


def make_binding(chord):
    key, modifiers, modifier_mask = parse_chord(chord)

    cp = PUA_BASE + (KEY_IDS[key] << 4) + modifier_mask

    if cp > PUA_END:
        raise ValueError(f"{chord}: U+{cp:04X} outside managed range")

    return iterm2.KeyBinding(
        character=ord(key),
        modifiers=modifiers,
        keycode=None,
        action=iterm2.BindingAction.HEX_CODE,
        param=chr(cp).encode("utf-8").hex(" "),
        version=None,
        label=None,
    )


def binding_codepoint(binding):
    if binding.action != iterm2.BindingAction.HEX_CODE:
        return None

    try:
        text = bytes.fromhex(binding.param).decode("utf-8")
    except (TypeError, ValueError, UnicodeDecodeError):
        return None

    if len(text) != 1:
        return None

    return ord(text)


def is_ours(binding):
    cp = binding_codepoint(binding)
    return cp is not None and PUA_BASE <= cp <= PUA_END


def same_chord(a, b):
    return (
        a.character == b.character
        and set(a.modifiers) == set(b.modifiers)
        and a.keycode == b.keycode
    )


async def install_custom_keys(connection):
    existing = list(
        await iterm2.async_get_global_key_bindings(connection)
    )

    ours = [b for b in existing if is_ours(b)]
    bindings = [b for b in existing if not is_ours(b)]

    for binding in ours:
        cp = binding_codepoint(binding)
        print(f"REMOVE  U+{cp:04X}  {binding.param}")

    for chord in sorted(CUSTOM_KEYS):
        new = make_binding(chord)

        collision = next(
            (b for b in bindings if same_chord(b, new)),
            None,
        )

        if collision is not None:
            print(
                f"SKIP    {chord:20} existing binding: "
                f"{collision.action} {collision.param!r}"
            )
            continue

        bindings.append(new)

        cp = binding_codepoint(new)
        print(
            f"ADD     {chord:20} "
            f"U+{cp:04X}  {new.param}"
        )

    await iterm2.async_set_global_key_bindings(
        connection,
        bindings,
    )

MODS = {
    1 << 0: "shift",
    1 << 1: "ctrl",
    1 << 2: "alt",
    1 << 3: "cmd",
}

def decode_key(ch):
    """
    Decode a character from the private‑use area into its base key and a set of modifier names.

    Parameters
    ----------
    ch: str
        A single‑character string representing the encoded key.

    Returns
    -------
    tuple[str, set[str]]

    The base key (a‑z) and a set containing any of ``"shift"``, ``"ctrl"``, ``"alt"``, ``"cmd"`` that were encoded.
    """
    value = ord(ch) - PUA_BASE

    key_id = value >> 4
    modifier_mask = value & 0xF

    key = next(k for k, v in KEY_IDS.items() if v == key_id)

    mods = [
        name
        for bit, name in MODS.items()
        if modifier_mask & bit
    ]

    return str.join('+', mods + [key])

def list_pua_keys():

    table = Table()
    table.add_column("Chord")
    table.add_column("U+ code")
    table.add_column("Param")
    for chord in sorted(CUSTOM_KEYS):
        binding = make_binding(chord)
        table.add_row(chord, f"U+{binding_codepoint(binding):04X}", binding.param)
    rich.print(table)


if __name__ == "__main__":
    import sys
    if sys.argv[1] == "list_pua_keys":
        list_pua_keys()

