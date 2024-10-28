-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    print(vim.inspect(vim.treesitter.get_captures_at_cursor()))
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")
vim.cmd("nnoremap <leader>pi :Inspect<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences

-- TODO MOVE THIS FILE ELSEWHERE, is weird name and spot

-- TODO! remove once I am happy with new treesitter based highlights that aren't conflicting at all given treesitter highlights take precedence (IIUC) over "legacy" syntax highlights
vim.cmd [[
    hi clear Comment " clear it fixes the fg color ... b/c then yeah a comment doesn't have a fg color... ok... but can I add back color as a lower precedence rule?
    -- FYI... treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. must have to do with why it wins over syntax match highlights (prior way I did it)
]]
-- vim.api.nvim_create_autocmd("BufReadPost", {
--     callback = function()
--         vim.cmd("source ~/.config/nvim/lua/plugins/vimz/highlights.vim")
--     end
-- })
