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

-- coc-definition
-- JUMP to symbol's definition
vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', { silent = true })
-- vim.keymap.set('n', 'gd', '<Cmd>Telescope coc definitions<CR>', { silent = true })
vim.keymap.set('n', '<F12>', '<Plug>(coc-definition)', { silent = true })
-- vim.keymap.set('n', '<F12>', '<Cmd>Telescope coc definitions<CR>', { silent = true })

-- coc-type-definition
-- JUMP to current symbol's TYPE definition
--  i.e. if symbol is a variable that is an instance of the Person type then jumps to Person class
--  TODO HABITUATE THIS! it's useful, and differentiate vs coc-definition!
vim.keymap.set('n', 'gt', '<Plug>(coc-type-definition)', { silent = true })
-- vim.keymap.set('n', 'gt', '<Cmd>Telescope coc type_definitions<CR>', { silent = true })
-- FYI gt is tabnext normally, but I don't care about replacing it

-- coc-implementation
vim.keymap.set('n', '<leader>gi', '<Plug>(coc-implementation)', { silent = true })
-- vim.keymap.set('n', '<leader>gi', '<Cmd>Telescope coc implementations<CR>', { silent = true })

-- coc-declaration
vim.keymap.set('n', '<leader>ge', '<Plug>(coc-declaration)', { silent = true })
-- vim.keymap.set('n', '<leader>ge', '<Cmd>Telescope coc declaration<CR>', { silent = true })

-- coc-references
vim.keymap.set('n', '<leader>gr', '<Plug>(coc-references)', { silent = true })
-- vim.keymap.set('n', '<leader>gr', '<Cmd>Telescope coc references<CR>', { silent = true })
--
-- coc-references-used
-- same as coc-references minus the declaration
-- FYI also skips require/imports of a module! useful! only usages!
vim.keymap.set('n', '<leader>gru', '<Plug>(coc-references-used)', { silent = true })
-- vim.keymap.set('n', '<leader>gru', '<Cmd>Telescope coc references used<CR>', { silent = true })

-- FYI I am going back to coc's references picker, unfortunately
--  when I use telescope's ... it doesn't support :CocResume/:CocNext/:CocPrev (see keymaps below)
--   actually it does have ":Telescope resume" but AFAIK that is all, to resume last search, not specifically my references search (can use cache_picker but still no CocNext/CocPrev)
--  so I have to redo search each time! ouch
--  applies to all coc pickers
--  PRN investigate if I can get resume w/ telescope's picker which I prefer in some ways

-- Shift-F12 ==> <F24> (use ctrl-v in insert/cmdline modes to see keypress)
vim.keymap.set('n', '<F24>', '<Plug>(coc-references)', { silent = true })
-- vim.keymap.set('n', '<F24>', '<Cmd>Telescope coc references<CR>', { silent = true })

-- * formatting
local function format_selected()
    if vim.bo.filetype == "gitconfig" then
        vim.cmd("normal! gg=G")
    else
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Plug>(coc-format-selected)", true, true, true),
            "x",
            false
        )
    end
end

local function format_insert()
    if vim.bo.filetype == "gitconfig" then
        vim.cmd("normal! gg=G")
    else
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>:call CocAction('format')<CR>a", true, false, true),
            "i",
            false
        )
    end
end


---@diagnostic disable-next-line: unused-function
local function suck_a_dick_formatter()
    -- I can't throw this away! ChatGPT made it for me!
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    math.randomseed(os.time())
    for i = 1, #lines do
        lines[i] = lines[i]:gsub("%S", function(c)
            return math.random() > 0.5 and c:upper() or c:lower()
        end)
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function format_normal()
    if vim.tbl_contains({ "gitconfig", "make", "zsh" }, vim.bo.filetype) then
        -- suck_a_dick_formatter()
        vim.cmd("normal! gg=G")
    else
        vim.cmd("call CocAction('format')")
    end
end

vim.keymap.set('x', '<S-M-f>', format_selected)
vim.keymap.set('i', '<S[<8;11;21m-M-f>', format_insert)
vim.keymap.set('n', '<S-M-f>', format_normal)

vim.keymap.set('x', '<S-M-f>', format_selected)
vim.keymap.set('i', '<S-M-f>', format_insert)
vim.keymap.set('n', '<S-M-f>', format_normal)
