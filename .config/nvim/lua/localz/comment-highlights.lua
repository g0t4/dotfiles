local dump = require('helpers.dump')

-- TODO remove once reminders not needed
vim.cmd("nnoremap <leader>pc :lua vim.notify('use <leader>tsi now')<CR>")
vim.cmd("nnoremap <leader>pi :lua vim.notify('use <leader>tsi now')<CR>")
--
-- *** treesitter <leader>ts prefix, do I like this?
vim.cmd("nnoremap <leader>tsi :Inspect<CR>") -- vim.show_pos() -- colorful captures
vim.cmd("nnoremap <leader>tsii :Inspect!<CR>") -- vim.inspect_pos() -- detailed
vim.keymap.set('n', '<leader>tst', ":InspectTree<CR>")

vim.keymap.set('n', '<leader>tsd', function()
    local node = vim.treesitter.get_node()
    local info = format_dump(node)
    dump.ensure_open()
    dump.append(info)
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
