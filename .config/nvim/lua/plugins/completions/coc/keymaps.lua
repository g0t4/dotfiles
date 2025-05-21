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

vim.api.nvim_create_user_command('FormatBuffer', function()
    vim.fn.CocActionAsync('format')
end, { nargs = 0 })

vim.api.nvim_create_user_command('OrganizeImports', function()
    vim.fn.CocActionAsync('runCommand', 'editor.action.organizeImport')
end, { nargs = 0 })

vim.keymap.set('n', '<leader>oi', ':OrganizeImports<cr>', { silent = true })
