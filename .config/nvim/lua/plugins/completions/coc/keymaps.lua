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

-- vim.api.nvim_create_user_command('OrganizeImports', function()
--     vim.fn.CocActionAsync('runCommand', 'editor.action.organizeImport')
-- end, { nargs = 0 })

-- NO NO NO NO NO... this will rearrange and fuck up legit side effects (i.e. torch needs to come before faiss... stop using this nonsese.. import order should NEVER be willy nilly rearranged)
-- vim.keymap.set('n', '<leader>oi', ':OrganizeImports<cr>', { silent = true })




-- * CoCList/goto related keymaps
-- TODO habituate
--   this is like loclist and quickfix, but specific to CoC
--   i.e. if you find refs => go to first one => wanna go next in list:
--     :CocNext/:CocPrev
-- FYI using <leader>c as prefix for now, that way these are "namespaced"
--   means WhichKey will help me recall them
-- CocList has fuzzy matchers, so a nice way to grok the relevant info (i.e. diagnostics or outline)
--
vim.keymap.set('n', '<leader>cd', ':<C-u>CocList diagnostics<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>co', ':<C-u>CocList outline<CR>', { noremap = true, silent = true, nowait = true })
-- Search workspace symbols
vim.keymap.set('n', '<leader>cs', ':<C-u>CocList -I symbols<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cf', ':<C-u>CocFirst<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cl', ':<C-u>CocLast<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cn', ':<C-u>CocNext<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cp', ':<C-u>CocPrev<CR>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cr', ':<C-u>CocListResume<CR>', { noremap = true, silent = true, nowait = true })

vim.keymap.set('n', '<leader>ce', ':<C-u>CocList extensions<CR>', { noremap = true, silent = true, nowait = true })
-- habituating this should be helpful while I learn more about coc commands I am not yet using:
--   right after this opens, I can type to filter the list to a command so this is a super efficient way to not need keymaps for most commands
vim.keymap.set('n', '<leader>cc', ':<C-u>CocList commands<CR>', { noremap = true, silent = true, nowait = true })

-- * coc-callHierarchy related:
-- show hierarchy of incoming/outgoing calls
vim.keymap.set('n', '<leader>cci', ':<C-u>CocCommand document.showIncomingCalls<cr>', { noremap = true, silent = true, nowait = true })
vim.keymap.set('n', '<leader>cco', ':<C-u>CocCommand document.showOutgoingCalls<cr>', { noremap = true, silent = true, nowait = true })



-- * GoTo code navigation

vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', { silent = true })
-- vim.keymap.set('n', 'gd', '<Cmd>Telescope coc definitions<CR>', { silent = true })

vim.keymap.set('n', 'gy', '<Plug>(coc-type-definition)', { silent = true })
-- vim.keymap.set('n', 'gy', '<Cmd>Telescope coc type_definitions<CR>', { silent = true })

vim.keymap.set('n', '<leader>gi', '<Plug>(coc-implementation)', { silent = true })
-- vim.keymap.set('n', '<leader>gi', '<Cmd>Telescope coc implementations<CR>', { silent = true })

-- FYI I am going back to coc's references picker, unfortunately
--  when I use telescope's ... it doesn't support :CocResume/:CocNext/:CocPrev (see keymaps below)
--   actually it does have ":Telescope resume" but AFAIK that is all, to resume last search, not specifically my references search (can use cache_picker but still no CocNext/CocPrev)
--  so I have to redo search each time! ouch
--  applies to all coc pickers
--  PRN investigate if I can get resume w/ telescope's picker which I prefer in some ways

vim.keymap.set('n', '<leader>gr', '<Plug>(coc-references)', { silent = true })
-- vim.keymap.set('n', '<leader>gr', '<Cmd>Telescope coc references<CR>', { silent = true })

-- FYI S-F12 doesn't work b/c IIRC my profile in iTerm2 remaps it to a diff escape sequence... not sure what that was for anymore but if it was fish-shell I can probably reverse it?!
--   by the way <F12> and <S-M-F12> all work, and I see the entry in the profile => keys so yeah that has to be it
vim.keymap.set('n', '<S-F12>', '<Plug>(coc-references)', { silent = true })
-- vim.keymap.set('n', '<S-F12>', '<Cmd>Telescope coc references<CR>', { silent = true })

vim.keymap.set('n', '<F12>', '<Plug>(coc-definition)', { silent = true })
-- vim.keymap.set('n', '<F12>', '<Cmd>Telescope coc definitions<CR>', { silent = true })


-- * formatting
local function format_selected()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>(coc-format-selected)", true, true, true), "x", false)
end

local function format_insert()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>:call CocAction('format')<CR>a", true, false, true), "i", false)
end

local function format_normal()
    vim.cmd([[call CocAction('format')]])
end

vim.keymap.set('x', '<S-M-f>', format_selected)
vim.keymap.set('i', '<S-M-f>', format_insert)
vim.keymap.set('n', '<S-M-f>', format_normal)
