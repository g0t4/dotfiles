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




-- * CoCList/goto related keymaps
-- TODO habituate
--   this is like loclist and quickfix, but specific to CoC
--   i.e. if you find refs => go to first one => wanna go next in list:
--     :CocNext/:CocPrev
-- FYI using <leader>c as prefix for now, that way these are "namespaced"
--   means WhichKey will help me recall them
-- CocList has fuzzy matchers, so a nice way to grok the relevant info (i.e. diagnostics or outline)
--
vim.keymap.set('n', '<leader>ca', ':<C-u>CocList diagnostics<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>co', ':<C-u>CocList outline<CR>', { noremap = true, silent = true, nowait = true })
-- Search workspace symbols
vim.keymap.set('n', '<leader>cs', ':<C-u>CocList -I symbols<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cf', ':<C-u>CocFirst<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cl', ':<C-u>CocLast<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cn', ':<C-u>CocNext<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cp', ':<C-u>CocPrev<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cr', ':<C-u>CocListResume<CR>', { noremap = true, silent = true, nowait = true })
--
vim.keymap.set('n', '<leader>ce', ':<C-u>CocList extensions<CR>', { noremap = true, silent = true, nowait = true })
-- habituating this should be helpful while I learn more about coc commands I am not yet using:
--   right after this opens, I can type to filter the list to a command so this is a super efficient way to not need keymaps for most commands
vim.keymap.set('n', '<leader>cc', ':<C-u>CocList commands<CR>', { noremap = true, silent = true, nowait = true })
-- show hierarchy of incoming/outgoing calls
vim.keymap.set('n', '<leader>cci', ':<C-u>CocCommand document.showIncomingCalls<cr>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cco', ':<C-u>CocCommand document.showOutgoingCalls<cr>', { noremap = true, silent = true, nowait = true })
