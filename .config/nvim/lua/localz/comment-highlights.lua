-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    print(vim.inspect(vim.treesitter.get_captures_at_cursor()))
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")

vim.cmd("nnoremap <leader>pi :Inspect<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences


vim.api.nvim_set_hl(0, '@comment_todo', { fg = '#ffcc00' })                                         -- TODO test
vim.api.nvim_set_hl(0, '@comment_todo_bang', { bg = '#ffcc00', fg = "#1f1f1f", bold = true })       -- TODO! test
--
vim.api.nvim_set_hl(0, '@comment_asterisks', { fg = '#ff00c3' })                                    -- *** test
vim.api.nvim_set_hl(0, '@comment_asterisks_bang', { bg = '#ff00c3', fg = "#1f1f1f", bold = true })  -- ***! test

vim.api.nvim_set_hl(0, '@comment_prn', { fg = "#27AE60" })                                          -- PRN test
vim.api.nvim_set_hl(0, '@comment_prn_bang', { bg = "#27AE60", fg = "#1f1f1f", bold = true })        -- PRN! test

vim.api.nvim_set_hl(0, '@comment_single_bang', { fg = "#cc0000" })                                  -- ! test
vim.api.nvim_set_hl(0, '@comment_triple_bang', { bg = "#cc0000", fg = "#ffffff", bold = true })     -- !!! test

vim.api.nvim_set_hl(0, '@comment_single_question', { fg = "#3498DB" })                              -- ? test
vim.api.nvim_set_hl(0, '@comment_triple_question', { bg = "#3498DB", fg = "#1f1f1f", bold = true }) -- ??? test

-- FYI I am not attached to blue for cell_devider, it works fine for now though if I made more use of ?? then I might want this to differ
vim.api.nvim_set_hl(0, '@comment_cell_devider', { fg = '#3498DB' })                                    --%%
vim.api.nvim_set_hl(0, '@comment_cell_devider_bang', { bg = '#3498DB', fg = "#1f1f1f", bold = true })  --%%! test

