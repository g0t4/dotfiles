# Vim Mnemonics

*Note, I prefer either a single word (i.e. `y`ank) or a short phrase that rhymes*


- `A`ppend at the End
- `I`nsert at the Start
- [`J`oin (lines)](https://www.youtube.com/watch?v=1x9jRt53ZYA)
- `c`hange
- `d`elete
- `y`ank
- `t`ill / un`t`il
- `f`ind
- move/select
  - `b`ack a word
  - `w`ord / for`w`ard
  - `e`nd of word
  - `i`nner / `a`aroud
- `%` - percenthesis (parenthesis)

## WIP

- Line level (capitalized)
  - cursor movement
    - `H`ighest line (top)
    - `M`iddle line
    - `L`owest line (bottom)
    - `zz` (middle)
    - `zt` top
    - `zb` bottom
  - To the End of the line:
    - `C`hange
    - `D`elete
    - `Y`ank
  - `I`/`A` at the start/end of line
  - `J`oin lines
- `xp`ose => `transpose`
- surrounding (i.e. nvim-surround, et al)
  - `cs"` [c]hange [s]urrounding to _
  - `ds"` [d]elete [s]urrounding _
  - `ys{motion}"` [y]ou [s]urround (I hate this purported mnemonic, it's not at all memorable) - `y`oke? (as in attach a cross bar with ends that attach to cattle?) need smth new... or maybe this one is just gonna have to be its c/d/y and c/d have good mnemonics, so y is left over?
- command help
  - `:h c` -  can lookup any char and get its help page
  - `:h index` - index of builtin keymaps (not user defined)
  - `:h c_` - cmap builtins
  - `:h down` - wilder/nvim-cmp cmdline completions can be fuzzy filtered (FYI lowercase matches case insensitivee, uppercase letter only match uppercase - in most fuzzy match algos)
- modes
    - commands for managing user-defined key`map`s  (TODO prune to critical only, i.e. probaly `x`map/`v`map are probably the only commonly used that aren't obvious
      - `i`map (insert)
      - `n`map (normal)
      - `c`map (cmdline)
      - `s`map (select)
      - `x`map (visual) *** need mnemonic here (maybe smth about how this is like `v`map but just for visual, like X out select? = nah)
      - `o`map (operator-pending)
      - `t`map (terminal)
      - multiple modes:
        - `map` = normal,visual,select,operator-pending
        - `v`map = visual,select
        - map`!` = insert,cmdline
        - `l`map = insert,cmdline,lang-arg
    - `i`nsert
    - `n`ormal
    - `c`mdline
    - `v`isual
    - `s`elect
    - `t`erminal
    - `:h vim-modes`
