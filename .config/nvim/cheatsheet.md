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
    - `(` / `)` - start of sentence
    - `{` / `}` - start of paragraph - basically, the next blank line
    - `[[` / `]]` -  start of section
    - `[]` / `][` -  end of section
- small movements
    - `w` -  start of next word
    - `e` -  end of next word
    - `b` -  start of previous word
    - `0` -  start of line
    - `^` -  first non-whitespace character of line
    - `$` -  end of line
    - `f<char>` -  next occurrence of `<char>` on current line
    - `F<char>` -  previous occurrence of `<char>` on current line
    - `t<char>` -  before next occurrence of `<char>` on current line
    - `T<char>` -  after previous occurrence of `<char>` on current line
    - `;` - repeat last `f`, `t`, `F`, or `T` movement
    - `,` - repeat last `f`, `t`, `F`, or `T` movement in opposite direction

