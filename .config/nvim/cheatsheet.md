# vim/nvim cheatsheet

## keymaps

### help

- help for builtin keymaps/commands
    - `:h zz` - help for `zz`, etc
    - `:h Ctrl-W`
- list user defined
    - `:map` - list all
    - `:map <leader>` - list all with leader
    - `:nmap` - list normal
        - `:imap` / `:vmap` / `:cmap` / `:tmap`
- terms
    - `motion` - moves cursor or targets a chunk of text (`:h motion`)
    - `operator` - acts on a motion (hence operator first => motion/text-object)
    - `text-objects` motions - target a block of text (i.e. word, sentence, paragraph, section, etc)
    - `count` - repeat following command
    - `register` - a place to store text
- links
    - [neovim quickref](https://neovim.io/doc/user/quickref.html)
        - `:h quickref`

### indentation

- change indentation
    - `gg=G` - reindent entire file (`gg` = top, `=` - reindent, to `G` = bottom)
    - `>>` - indent current line
    - `<<` - unindent current line
    - `==` - auto-indent current line
- paste
    - `[p` - paste before cursor w/ adjust indent to current line
    - `]p` - paste after "
- TODO vim tab settings
- TODO nvim editorconfig support (add .editorconfig)
- TODO section on formatting (not here)

### document movement

- large movements
    - scroll current cursor line to... (***)
        - `zz` or `z.` - center of screen
        - `zt` or `z<CR>` - top of screen
        - `zb` or `z-` - bottom of screen
    - scroll left/right
        - `N zh` - left
        - `N zl` - right
        - `zH` / `zL` - half screen left/right
    - move cursor only
        - `H` -  top of screen
        - `M` -  middle of screen
        - `L` -  bottom of screen
    - top/bottom
        - `gg` -  top of document
        - `G` -  bottom of document
    - page up/down
        - `Ctrl+U` - up half
            - `Ctrl+D` - down half
        - `Ctrl+B` / `PageUp` - up full
            - `Ctrl+F` / `PageDown` - down full
        - `Ctrl+E` - 1 line up
            - `Ctrl+Y` - 1 line down
        - all the above can be prefixed with a count
        - and can change amount of lines each moves by, amounts above are defaults
        - FYI, case is ignored for `Ctrl` keymaps
- medium movements
    - `(` / `)` - by sentence
    - `{` / `}` - by paragraph (*** - basically by empty lines)
    - `[[` / `]]` - by section (in markdown, by headers)
        - `[]` / `][` - end of section
- small movements
    - by word
        - `w` -  start of next word
            - `b` -  start of previous word
        - `e` -  end of next word
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

### windows

- `Ctrl-W` prefix
    - `h` / `j` / `k` / `l` - move to window left / down / up / right
        - `Up` / `Down` / `Left` / `Right`
    - resize:
        - `==` - make all windows equal size
        - `+` / `-` - increase / decrease height (add N before Ctrl-W)

