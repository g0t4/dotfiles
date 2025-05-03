local dump = require('helpers.dump')
-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    print(vim.inspect(vim.treesitter.get_captures_at_cursor()))
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")

vim.cmd("nnoremap <leader>pi :Inspect<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences
vim.cmd("nnoremap <leader>pii :Inspect!<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences

vim.keymap.set('n', '<leader>pd', function()
    local node = vim.treesitter.get_node()
    local info = dump_formatter(node)
    dump.ensure_open()
    dump.append(info)
end)

vim.keymap.set('n', '<leader>pt', function()
    -- show treesitter node text for node under cursor
    local node = vim.treesitter.get_node()
    local text = vim.treesitter.get_node_text(node, 0)
    print(text)
end)

vim.api.nvim_set_hl(0, '@comment_todo', { fg = '#ffcc00' }) -- TODO test
vim.api.nvim_set_hl(0, '@comment_todo_bang', { bg = '#ffcc00', fg = "#1f1f1f", bold = true }) -- TODO! test
--
vim.api.nvim_set_hl(0, '@comment_asterisks', { fg = '#ff00c3' }) -- *** test
vim.api.nvim_set_hl(0, '@comment_asterisks_bang', { bg = '#ff00c3', fg = "#1f1f1f", bold = true }) -- ***! test

vim.api.nvim_set_hl(0, '@comment_prn', { fg = "#27AE60" }) -- PRN test
vim.api.nvim_set_hl(0, '@comment_prn_bang', { bg = "#27AE60", fg = "#1f1f1f", bold = true }) -- PRN! test

vim.api.nvim_set_hl(0, '@comment_single_bang', { fg = "#cc0000" }) -- ! test
vim.api.nvim_set_hl(0, '@comment_triple_bang', { bg = "#cc0000", fg = "#ffffff", bold = true }) -- !!! test

vim.api.nvim_set_hl(0, '@comment_single_question', { fg = "#3498DB" }) -- ? test
vim.api.nvim_set_hl(0, '@comment_triple_question', { bg = "#3498DB", fg = "#1f1f1f", bold = true }) -- ??? test

vim.api.nvim_set_hl(0, '@comment_cell_devider', { underline = true }) --%%
vim.api.nvim_set_hl(0, '@comment_cell_devider_bang', { bold = true, underline = true }) --%%! test
