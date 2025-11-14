# vim/nvim cheatsheet

## keymaps

### misc

- relocate these as needed
- `<Shift+Tab>` is useful to bypass tab completion (i.e. with copilot or coc, if you use tab to complete either)

### commands

- `:h Ex-commands` - index of cmds
- `:h :{cmd}` - help for command
- many commands take optional commands
  - `:verbose nmap` - show normal mode user mapped keys + where they were defined
  - `:vsplit :new`
  - second `:` is optional
  - see `:h :vsplit` => shows `:[N]vs[plit] [++opt] [+cmd] [file]` (note `[+cmd]`)

### basic commands (mostly normal mode)

- `d{motion}` - delete
  - `x` == `dl` (after cursor)
  - `X` == `dh` (before cursor)
  - `dd` - linewise
  - `D` - to end of line
  - TODO document implicit yank (based on clipboard setting?)
    - `"adw` - delete word into register `a`
  - `J`/`gJ`/`:j[oin]` - join lines
- `c{motion}` - change (delete + insert)
  - `R`/`gR` - enter replace mode
  - `cc`/`S` - linewise
  - `C` - to end of line
  - `s` - substitute # chars == `cl`
  - `r` - replace char under cursor
  - change case
    - `~{motion}`/`gU{motion}`/`gu{motion}` - switch/upper/lower
    - `g~~`/`gUU`/`guu` - linewise - switch/upper/lower
    - `g?`/`g??` - rot13 encode, lol (video?)
  - inc/decrement numbers, (i.e. to make a numbered list macro?)
    - `Ctrl-A` - increment, `2,<C-A>` - increment by 2
    - `Ctrl-X` - decrement
- indent
  - `<{motion}`/`>{motion}` - shift left/right
  - `<<`/`>>` - linewise
  - `:>[>>>]`/`:<[<<<]`- command mode indent 1 for each >/<
- undo/redo
  - `u` - undo
  - `Ctrl-R` - redo
  - `U` - undo all changes on line
  - `:changes` - list changes
- `.` - repeat last change

- TODO flush out:

- `y{motion}` - yank (copy)
  - `yy` - linewise
- `v` - visual mode
  - `V` - visual line mode
  - `Ctrl-V` - visual block mode
- `p` - paste after cursor
  - `P` - paste before cursor
- `{filter}`
- `:s[ubstitute]`
- align
  - `:left`, `:center`, `:right`
- format
  - `gq{motion}` - format
    - `gqq` - format line
  - `gw{motion}` - format and preserve cursor position
    - `gww` - format word
- `:sort`

### tips

- `0D` to clear a line (not delete it) and stay in normal mode
  - `cc` or `0C` to do the same but enter insert mode
  - helpful when adding a blank line above/below a comment and the new line is started w/ a comment you don't want

### help

- help for builtin keymaps/commands
  - `:h zz` - help for `zz`, etc
  - `:h Ctrl-W`
- list user defined
  - `:map` - list all
  - `:map <leader>` - list all with leader
  - `:nmap` - list normal
    - `:imap` / `:vmap` / `:cmap` / `:tmap`
  - `:map <leader>` - prefixed with leader
    - `<leader>` - a user defined key prefix (default is `\`), I have mine set to `' '` (space)
  - `:nmap g` - list normal prefixed with `g`
- terms
  - `motion` - moves cursor or targets a chunk of text (`:h motion`)
  - `operator` - acts on a motion (hence operator first => motion/text-object)
  - `text-objects` motions - target a block of text (i.e. word, sentence, paragraph, section, etc)
  - `count` - repeat following command
  - `register` - a place to store text
- links
  - [neovim quickref](https://neovim.io/doc/user/quickref.html)
    - `:h quickref`

### coc

These are custom mappings in coc to add LSP features based on LSP availability... most of these are suggested in coc docs:

- format
  - `<leader>f` - format selected
  - `Shift-Alt-F` - format entire file (not in suggested set, mirrors vscode)
- rewrite
  - `<leader>rn` - rename symbol
  - `<leader>r` - refactor selection
  - `<leader>re` - refactor
- actions
  - `<leader>cl` - code lens actions
  - `<leader>ac` - code actions cursor
  - `<leader>a` - code actions selected
  - `<leader>as` - code actions source
- go to
  - `gd` - definition
  - `gy` - type definition
  - `gi` - implementation
  - `gr` - references
- diagnostics
  - `[g` - previous diagnostic
  - `]g` - next diagnostic

### avante

- `<leader>at` - toggle chat pane
- selections:
  - `aa` - ask
  - `ae` - edit
- TODO review others I might wanna use

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

### search

- Cmdline can be used to search with `/` (forward) and `?` (backward)
  - `/foo<CR>` will jump to the first match
  - `n` and `N` cycle matches (forward/backward)
- Also, use `*` to search forward for the exact word under cursor, and `#` to search backward
  - `g*`/`g#` is the same search without `\<` and `\>` which means it doesn't have to be an exact match

### document movement

- large movements
  - scroll current cursor line to...
    - `zz` or `z.` - center of screen
    - `zt` or `z<CR>` - top of screen
    - `zb` or `z-` - bottom of screen
  - scroll left/right
    - `N zh` - left
    - `N zl` - right
    - `zH` / `zL` - half screen left/right
  - move cursor only
    - `H` - top of screen
    - `M` - middle of screen
    - `L` - bottom of screen
  - top/bottom
    - `gg` - top of document
    - `G` - bottom of document
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
  - `{` / `}` - by paragraph (by newline) // favorite (I leave new lines strategically now)
  - `[[` / `]]` - by section (in markdown, by headers)
    - `[]` / `][` - end of section
- small movements
  - by word
    - `w` - start of next word
      - `b` - start of previous word
    - `e` - end of next word
      - `ge` - end of previous word
  - current line
    - `0` - start of line
    - `^` - first non-whitespace character of line
    - `$` - end of line
  - to character (f = find, t = till)
    - Notes:
      - I used to think of `t` == `to`, but `till` is more accurate b/c it stops before the char
    - `f<char>` - next occurrence of `<char>` on current line
    - `F<char>` - previous occurrence of `<char>` on current line
    - `t<char>` - before next occurrence of `<char>` on current line
    - `T<char>` - after previous occurrence of `<char>` on current line
    - `;` - repeat last `f`, `t`, `F`, or `T` movement
    - `,` - repeat last `f`, `t`, `F`, or `T` movement in opposite direction

### windows

- `Ctrl-W` prefix
  - `h` / `j` / `k` / `l` - move to window left / down / up / right
    - `Up` / `Down` / `Left` / `Right`
  - resize
    - `==` - make all windows equal size
    - `+` / `-` - increase / decrease height # lines (use N before Ctrl-W)
    - `>` / `<` - increase / decrease width # columns

### text objects

- `i` = inner (no whitespace), `a` = a/around (whitespace around included)
- `iw`/`aw` - word
  - with `iw`, whitespace isn't included, which means whitespace between words is a separte inner word
    - thus, `v4iw` == `v2aw`
- `iW`/`aW` - WORD (whitespace separated)
- `is`/`as` - sentence
- `ip`/`ap` - paragraph
- blocks (by surrounding char)

  - `[`, `(`==`b`, `{`==`B`, `<`/`>`, `"`, `'`, backticks
  - thus `vi[` selects between `[` and `]`
  - FYI `va[` also selects the surrounding brackets!
  - SPANS multiple lines!
  - SUPER USERFUL in CODE

- Examples:
  - `vaw`, `viw`, etc (select) - visually see what each does, good for praticing (no command, just select text)
  - `daw`, `dap`, `das` (delete) - read nicely, try `diw` too see how whitespace is not deleted
  - `caw`, `ciw` (change) => compare how the former is somewhat odd b/c it removes whitespace around too

### nvim-surround

- Wrapping text with '")}] etc - matching pairs
- [wiki with examples](https://github.com/kylechui/nvim-surround/wiki/getting-started-for-beginners)
- Normal mode
  - `cs{target}{replace}` (change)
  - `ds{target}` (delete)
  - `ys{object}{char}` (add)
    - `ys4aw"` - surround 4 inner "words with double quotes"
      - FYI when you use `ysiw` it seems to switch into a select like mode where you can see what will be wrapped
      - prefer `aw` over `iw` for spanning multiple words
    - `ySSt{tag}` - `<p>text</p>`
- Visual mode
  - `S{with}` => `VS"`, `viwS"` surround inner word with ""
- Insert mode
  - TODO
- Custom config?

### recording macros

- `q{register}` - start recording
  - `q` - stop recording
- `@{register}` - replay
  - `@@` - replay last

### similar apps

- `kindaVim` - macOS app, turns every app into a vim like app (normal mode)
  - `Esc` into normal mode, `i` into regular mode? Or is it an insert mode?
  - text boxes, i.e. URL bar/alfred search/etc
    - `dw`/`db` delete word!
  - `gg/G` - top/bottom - rocks in Finder!
  - `Ctrl-U/D/F/B/Y/E` - scroll up/down
  - `hjkl` of course (i.e. Finder up down)
  - WIP assess how I like it
- `homerow` - macOS => click any button with vim motion like shortcuts
  - 1 to 2 char combos for all buttons, using Accessibility framework
  - `Shift-Cmd-Space` - toggle
  - works GREAT in browsers, macOS settings, FCPX, all the damn tiny buttons that are impossible to click and take forever to drag to... YES
  - TODO are the labels consistent? assuming screen contents are same?
