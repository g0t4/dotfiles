local messages = require("devtools.messages")
local inspect = require("devtools.inspect")

-- *** treesitter <leader>ts prefix, do I like this?
vim.cmd("nnoremap <leader>tsi :Inspect<CR>") -- vim.show_pos() -- colorful captures
vim.cmd("nnoremap <leader>tsii :Inspect!<CR>") -- vim.inspect_pos() -- detailed
vim.keymap.set('n', '<leader>tst', ":InspectTree<CR>")

vim.keymap.set('n', '<leader>tsd', function()
    local messages = require("devtools.messages")
    local node = vim.treesitter.get_node()
    -- TODO add color to output
    local info = format_dump(node)
    messages.ensure_open()
    messages.append(info)
end)

local query = vim.treesitter.query

vim.keymap.set('n', '<leader>tsc', function()
    local current_node = vim.treesitter.get_node():root()
    messages.open_append(inspect(current_node))

    -- local bufnr = vim.api.nvim_get_current_buf()
    -- for id, node, metadata, match in query:iter_captures(current_node, bufnr, first, last) do
    --     local name = query.captures[id] -- name of the capture in the query
    --     -- typically useful info about the node:
    --     local type = node:type() -- type of the captured node
    --     local row1, col1, row2, col2 = node:range() -- range of the capture
    --     -- ... use the info here ...
    -- end
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
