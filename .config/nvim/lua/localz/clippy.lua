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

TODO can I just setup to always use osc52 escape codes and forget about macos/linux etc if I am always using a shell that supports them?
--
--
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
local function copy(lines, _)
    require('osc52').copy(table.concat(lines, '\n'))
end
--
local function paste()
    return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
end
--
vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
}
--
-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set('n', '<leader>c', '"+y')
vim.keymap.set('n', '<leader>cc', '"+yy')
--
-- Note that if you set your clipboard provider like the example above, copying
-- text from outside Neovim and pasting with <kbd>p</kbd> won't work. But you can
-- still use the paste shortcut of your terminal emulator (usually
-- -- <kbd>ctrl+shift+v</kbd>).
