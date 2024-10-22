-- see:   :h osc52...
-- TODO revisit later

-- IDEAS in this osc52 plugin (predates nvim builtin support for osc52) that still has relevant config ideas:
--    https://github.com/ojroques/nvim-osc52

local function copy(lines, _)
    require('osc52').copy(table.concat(lines, '\n'))
end

local function paste()
    return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
end

vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
}

-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set('n', '<leader>c', '"+y')
vim.keymap.set('n', '<leader>cc', '"+yy')

-- Note that if you set your clipboard provider like the example above, copying
-- text from outside Neovim and pasting with <kbd>p</kbd> won't work. But you can
-- still use the paste shortcut of your terminal emulator (usually
-- <kbd>ctrl+shift+v</kbd>).
