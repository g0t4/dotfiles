--
-- * TODO try to setup snippets to tab through the parameters? I don't use these often so for now its ok to be "broken" b/c it just inserts defaulst then
-- vim.api.nvim_set_keymap('i', '<Right>', [[
--     coc#jumpable(1) ? '<C-r>=coc#rpc#request("snippetNext", [])<CR>' : '<Right>'
-- ]], { noremap = true, silent = true, expr = true })
--
-- vim.api.nvim_set_keymap('i', '<Left>', [[
--     coc#jumpable(-1) ? '<C-r>=coc#rpc#request("snippetPrev", [])<CR>' : '<Left>'
-- ]], { noremap = true, silent = true, expr = true })
--
-- TEST with: `writefi<ENTER>` in a python file, there are two snippet placeholders (filename and content)
--

-- " Add `:Format` command to format current buffer
vim.api.nvim_command([[
command! -nargs=0 Format :call CocActionAsync('format')
]])

-- " Add `:Fold` command to fold current buffer
vim.api.nvim_command([[
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
]])

-- " Add `:OR` command for organize imports of the current buffer
vim.api.nvim_command([[
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')
]])

vim.keymap.set('n', '<leader>oi', ':CocCommand editor.action.organizeImport<cr>', { silent = true })
