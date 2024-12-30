run `nvim -V1` and try typing commands, something from notify is causing issues and needs researched

ALSO this might be why randomly my lua settings (i.e. for textwidth is not set to 0 but 200.... randomly I get line wrapping when I configured that explicitly not to... smth with my lua ftplugins IIGC)


- this `autocmd! ___cmp___` will remove the issue when typing in the command line, still can tab to trigger issue...
- So, problem is with cmdlinechanged and tab key in cmdline
... i.e. around these autocmds:
:autocmds
...
___cmp___  CmdlineChanged
    *         <Lua 150: ~/.local/share/nvim/lazy/nvim-cmp/lua/cmp/utils/autocmd.lua:22> [nvim-cmp: autocmd: CmdlineChanged]
___cmp___  CmdlineEnter
    *         <Lua 146: ~/.local/share/nvim/lazy/nvim-cmp/lua/cmp/utils/autocmd.lua:22> [nvim-cmp: autocmd: CmdlineEnter]
___cmp___  CmdlineLeave
    *         <Lua 153: ~/.local/share/nvim/lazy/nvim-cmp/lua/cmp/utils/autocmd.lua:22> [nvim-cmp: autocmd: CmdlineLeave]
- AND IIAC this cmap:
:cmap
c  <Tab>       * <Lua 361: ~/.local/share/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:133>
                 cmp.utils.keymap.set_map
- Naturally: `cunmap <Tab>` will stop it and of course nvim-cmp completion cmdline no longer works

ALSO happening on / completions too.. a bit harder to see erorr b/c it can disappear but still obvious

BTW this still fails evenn if I disable COC for completions (other scenarios)

BTW issue is not b/c of nvim-notify (it just happens the error is thrown during some call to notify... but it happens w/o nvim-notify - regular vim.notify too)
IIGC is this to do with a buffer for the completion results? ... and IIGC then the completion results aren't being cached b/c of buffer creation issues?



