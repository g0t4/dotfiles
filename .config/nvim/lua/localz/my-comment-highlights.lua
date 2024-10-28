-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    print(vim.inspect(vim.treesitter.get_captures_at_cursor()))
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")
vim.cmd("nnoremap <leader>pi :Inspect<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences

vim.api.nvim_set_hl(0, '@comment_todo', { fg = '#ffcc00' })                                                     -- TODO test
vim.api.nvim_set_hl(0, '@comment_todo_bang', { bg = '#ffcc00', fg = "#1f1f1f", bold = true })                   -- TODO! test
--
vim.api.nvim_set_hl(0, '@comment_asterisks', { fg = '#ff00c3' })                                                -- *** test
vim.api.nvim_set_hl(0, '@comment_asterisks_bang', { bg = '#ff00c3', fg = "#1f1f1f", bold = true })              -- ***! test
vim.api.nvim_set_hl(0, '@comment_prn', { fg = "#27AE60" })                                                      -- PRN test
vim.api.nvim_set_hl(0, '@comment_prn_bang', { bg = "#27AE60", fg = "#1f1f1f", bold = true })                    -- PRN! test
vim.api.nvim_set_hl(0, '@comment_single_bang', { fg = "#cc0000" })                                              -- ! test
vim.api.nvim_set_hl(0, '@comment_triple_bang', { bg = "#cc0000", fg = "#ffffff", bold = true })                 -- !!! test
vim.api.nvim_set_hl(0, '@comment_single_question', { fg = "#3498DB" })                                          -- ? test
vim.api.nvim_set_hl(0, '@comment_triple_question', { bg = "#3498DB", fg = "#1f1f1f", bold = true })             -- ??? test

-- -- TODO! remove once I am happy with new treesitter based highlights that aren't conflicting at all given treesitter highlights take precedence (IIUC) over "legacy" syntax highlights
-- vim.cmd [[
--     hi clear Comment " clear it fixes the fg color ... b/c then yeah a comment doesn't have a fg color... ok... but can I add back color as a lower precedence rule?
--     " FYI... treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. must have to do with why it wins over syntax match highlights (prior way I did it)
-- ]]
-- vim.api.nvim_create_autocmd("BufReadPost", {
--     callback = function()
--         vim.cmd("source ~/.config/nvim/lua/plugins/vimz/highlights.vim")
--     end
-- })
