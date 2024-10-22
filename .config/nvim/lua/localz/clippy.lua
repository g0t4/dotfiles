-- FYI old clipboard config:
--- clipboard
vim.o.clipboard = 'unnamedplus' -- use +/* which on macOS are wired to system clipboard for yank/paste
-- FYI clipboard setting used when you don't specify the register to yank to, i.e. `yy` vs `"+yy`
-- so, normally `yy` would yank to the " register, which is an isolated clipboard within vim, hence the need to use "+yy to yank to the system clipboard
-- so, setting unnamedplus => makes `yy` == `"+yy` and `p` == `"+p` etc.

-- clipboard provider
-- this is how nvim wires up +/* registers to system clipboard
-- FYI `:registers` will show if there is a clipboard provider for +/* registers
-- on ubuntu machine, over SSH, I see
--     clipboard: No provider. Try ":checkhealth" or ":h clipboard".
--

-- *** ideas
-- TODO can I just setup to always use osc52 escape codes and forget about macos/linux etc if I am always using a shell that supports them?
-- see:   :h osc52...
-- IDEAS in this osc52 plugin (predates nvim builtin support for osc52) that still has relevant config ideas:
--    https://github.com/ojroques/nvim-osc52
--
-- i.e.
--
-- function copy()
--   if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
--     require('osc52').copy_register('+')
--   end
-- end
--
-- vim.api.nvim_create_autocmd('TextYankPost', {callback = copy})
--

-- *** test osc52 shell support w/o nvim:
--    echo -e "\033]52;;$(echo -n jerk | base64)\a"
--    # should paste "jerk" if works (works local and remote)

-- *** set clipboard provider (for +/*) to use osc52
--   FYI nvim 10.2+ has smth builtin and it doesn't work over SSH, so I am manually specifying to use osc52 module and this works!
--   FYI also the new nvim 10.2+ mechanism appears disabled when setting clipboard=unnamedplus above, so I also needed this for that reason
vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
}

-- -- wrong module now, but this can help troubleshoot w/o using the clipboard provider mechanism (which in prev testing swallowed errors in require non-existant module)
-- vim.keymap.set('n', '<leader>c', function()
--     require('osc52').copy_operator()
-- end, { expr = true })


-- Note that if you set your clipboard provider like the example above, copying
-- text from outside Neovim and pasting with <kbd>p</kbd> won't work. But you can
-- still use the paste shortcut of your terminal emulator (usually
-- -- <kbd>ctrl+shift+v</kbd>).
