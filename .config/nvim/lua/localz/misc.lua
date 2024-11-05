-- cursor block in insert:
vim.cmd(":set guicursor=i:block")



vim.cmd([[
    " TODO fix when close the original file doesn't show
    command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                  \ | wincmd p | diffthis
]])




-- *** Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file
vim.cmd("nnoremap <c-s> :w<CR>")
vim.cmd("vnoremap <c-s> <Esc><c-s>gv") -- esc=>normal mode => save => reselect visual mode, not working... figure out later
vim.cmd("inoremap <c-s> <c-o><c-s>")

-- F9 == quit all
vim.cmd("nnoremap <F9> :qall<CR>")
-- perhaps I am doing something wrong if I need F9.. but I love this, open lots of tabs to test neovim config changes and just wanna close w/o BS... also love one click quit if no changes
-- FYI F10 is F9 + re-run nvim (in keyboard maestro to relaunch nvim after quitting)


-- map [Shift]+Ctrl+Tab to move forward/backward through files to edit, in addition to Ctrl+o/i
--   that is my goto key combo, perhaps I should learn o/i instead... feel like many apps use -/+ for this, vscode for shizzle
vim.api.nvim_set_keymap('n', '<C-->', '<C-o>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-->', '<C-i>', { noremap = true, silent = true })
--  FYI in iTerm => Profiles -> Keys -> Key Mappings -> removed "send 0x1f" on "ctrl+-" ... if that breaks something, well you have this note :)

-- *** help
--
-- start typing :help then Ctrl+R, Ctrl+W takes word under cursor
vim.api.nvim_set_keymap('n', '<F1>', ':help <C-R><C-W><CR>', { noremap = true, silent = true })
--
-- in visual mode, press F1 to search for selected text
-- TODO write func to see if selected text is empty and do word under cursor instead => right now its just copying the letter under the cursor, which is fine for now but not ideal
vim.api.nvim_set_keymap('x', '<F1>', 'y:help <C-R>"<CR>', { noremap = true, silent = true })
vim.keymap.set('v', '<F1>', function()
    -- TODO make this handle 'n' normal mode too?
    -- local mode = vim.fn.visualmode()

    -- marks store start and end of visual selection
    --    this is why '<,'> is inserted into command line when you select text! now it makes sense! ' == mark, </> are the mark "register" names
    local start_pos = vim.fn.getpos("'<")
    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_pos = vim.fn.getpos("'>")
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    print("start/end", vim.inspect(start_pos), "/", vim.inspect(end_pos))
    if start_line == end_line or start_col == end_col then
        print("only one char")
        vim.cmd('normal! w') -- selects word under cursor (since one char alone isn't really a selection and if it is then this won't change it!)
        -- think of this as not requiring user to make simple selections, do it for them
    end

    -- yank visual selection into " register
    vim.cmd('normal! ""y')

    local search_term = vim.fn.getreg("\"")
    vim.cmd('help ' .. search_term)
end)
