local default_options = { noremap = true, silent = true }

-- *** window keymaps
for _, arrow in ipairs({ "right", "left", "up", "down" }) do
    -- simpler:
    -- vim.keymap.set({ "n" }, "<M-" .. arrow .. ">", "<C-W><" .. arrow .. ">", default_options)
    -- vim.keymap.set({ "i" }, "<M-" .. arrow .. ">", "<Esc><C-W><" .. arrow .. ">", default_options)
    --
    -- <Cmd>wincmd == one keymap for both modes (n/i) + preserve mode after switch
    --   also, this adds 4 fewer keymaps overall, so when I use :map to list them all, I see fewer
    local dir = arrow == "left" and "h" or arrow == "right" and "l" or arrow == "up" and "k" or "j"
    -- disable "i" insert mode b/c I use alt+right for accept next work in suggestions
    vim.keymap.set({ "n" }, "<M-" .. arrow .. ">", "<Cmd>wincmd " .. dir .. "<CR>", default_options)
end
-- FYI can use Shift+Alt+arrows to move some other thing, might even want that for window moves if not something else b/c that is what I use in iterm2 for switching panes in a split tab/window

-- *** tab keymaps
vim.keymap.set({ "n", "i", "v" }, "<C-t>", "<Cmd>tabnew<CR>", default_options)
-- <C-M-arrow> == move tabs
vim.keymap.set({ "n", "i", "v" }, "<C-M-left>", "<Cmd>tabprevious<CR>", default_options)
vim.keymap.set({ "n", "i", "v" }, "<C-M-right>", "<Cmd>tabnext<CR>", default_options)

-- TODO buffer keymaps?



-- *** Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file
-- <cmd> preserves mode and is independent of initial mode
-- <cmd> also preserves visual mode selection!
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", default_options)
-- vim.cmd("nnoremap <c-s> :w<CR>")
-- vim.cmd("vnoremap <c-s> <Esc><c-s>gv") -- esc=>normal mode => save => reselect visual mode, not working... figure out later
-- vim.cmd("inoremap <c-s> <c-o><c-s>")

-- F9 == quit all
vim.keymap.set({ "v", "n", "i" }, "<F9>", "<cmd>qall<CR>", default_options)
vim.keymap.set({ "v", "n", "i" }, "<F8>", "<cmd>q<CR>", default_options)
-- perhaps I am doing something wrong if I need F9.. but I love this, open lots of tabs to test neovim config changes and just wanna close w/o BS... also love one click quit if no changes
-- FYI F10 is F9 + re-run nvim (in keyboard maestro to relaunch nvim after quitting)


-- map [Shift]+Ctrl+Tab to move forward/backward through files to edit, in addition to Ctrl+o/i
--   that is my goto key combo, perhaps I should learn o/i instead... feel like many apps use -/+ for this, vscode for shizzle
vim.keymap.set('n', '<C-->', '<C-o>', default_options)
vim.keymap.set('n', '<C-S-->', '<C-i>', default_options)
--  FYI in iTerm => Profiles -> Keys -> Key Mappings -> removed "send 0x1f" on "ctrl+-" ... if that breaks something, well you have this note :)



-- *** help
--
-- start typing :help then Ctrl+R, Ctrl+W takes word under cursor
vim.keymap.set('n', '<F1>', ':help <C-R><C-W><CR>', { noremap = true, silent = true })
--
vim.keymap.set('x', '<F1>', 'y:help <C-R>"<CR>', { noremap = true, silent = true })
vim.keymap.set('v', '<F1>', function()
    -- *** in visual mode, press F1 to search for selected text, or select word under cursor
    -- local mode = vim.fn.visualmode()

    -- current visual seletion start/end:
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    -- FYI '<, '> are positions of LAST visual selection (not current)
    -- this is why '<,'> is inserted into command line when you select text! now it makes sense! ' == mark, </> are the mark "register" names
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    -- vim.cmd('normal! gv') -- reselect LAST visual selection ('<,'> marks)

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- print("start/end", vim.inspect(start_pos), "/", vim.inspect(end_pos))
    if start_line == end_line and start_col == end_col then
        -- print("  only one char, expanding selection to word")
        vim.cmd('normal! iw') -- selects word under cursor (since one char alone isn't really a selection and if it is then this won't change it!)
        -- think of this as not requiring user to make simple selections, do it for them
    end

    -- yank selection into " register
    vim.cmd('normal! ""y')

    local search_term = vim.fn.getreg("\"")
    -- print("  search term: '", search_term, "' (w/o single quotes)")
    vim.cmd('help ' .. search_term)
end)

vim.keymap.set('c', '<F1>', function()
    -- *** help for cmdline contents
    local cmdline = vim.fn.getcmdline()

    -- use Ctrl+C to cancel cmdline mode (otherwise help won't show until after you exit cmdline mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), 'n', false)

    -- TODO if mutliple words, take first word that has help? OR word under cursor?
    vim.cmd('help ' .. cmdline, { silent = true })

    -- could attempt to put cmdline back so it can be edited again BUT people wanted help so stay in help, they can always uparrow to get back cmd next time they enter cmdline mode
    -- pointless to put back the cmdline unless someone was just gonna read the start of the help which is doubtfully enough
    -- vim.api.nvim_feedkeys(":", 'n', false)
end)

-- *** search for word under cursor, can also use alt+p/n from vim-illuminate
-- TODO is this the mapping I want? it is hard to activate but it works if I can remember it and use it often
vim.keymap.set('n', '<leader>/', function()
    vim.fn.execute("/" .. vim.fn.expand("<cword>"))
end)
