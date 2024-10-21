# vim/nvim cheatsheet

## keymaps

### document movement

- large movements
    - scroll current cursor line to... (***)
        - `zz` - center cursor
        - `zt` - top of screen
        - `zb` - bottom of screen
    - move cursor only
        - `H` -  top of screen
        - `M` -  middle of screen
        - `L` -  bottom of screen
    - top/bottom
        - `gg` -  top of document
        - `G` -  bottom of document
    - page up/down
        - `Ctrl+u` - up half
        - `Ctrl+d` - down half
        - `Ctrl+b` / `PageUp` - up full
        - `Ctrl+f` / `PageDown` - down full
- medium movements
    - `(` / `)` - by sentence
    - `{` / `}` - by paragraph (*** - basically by empty lines)
    - `[[` / `]]` - by section/{} in first column
    - `[]` / `][` - next/previous end of section
- small movements
    - by word
        - `w` -  start of next word
        - `e` -  end of next word
        - `b` -  start of previous word
        - `ge` -  end of previous word
    - current line
        - `0` -  start of line
        - `^` -  first non-whitespace character of line
        - `$` -  end of line
    - to character (f = find, t = till)
        - Notes:
            - I used to think of `t` == `to`, but `till` is more accurate b/c it stops before the char
        - `f<char>` -  next occurrence of `<char>` on current line
        - `F<char>` -  previous occurrence of `<char>` on current line
        - `t<char>` -  before next occurrence of `<char>` on current line
        - `T<char>` -  after previous occurrence of `<char>` on current line
        - `;` - repeat last `f`, `t`, `F`, or `T` movement
        - `,` - repeat last `f`, `t`, `F`, or `T` movement in opposite direction

