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
    vim.keymap.set({ "i", "n" }, "<M-" .. arrow .. ">", "<Cmd>wincmd " .. dir .. "<CR>", default_options)
end
-- FYI can use Shift+Alt+arrows to move some other thing, might even want that for window moves if not something else b/c that is what I use in iterm2 for switching panes in a split tab/window

-- TODO tab keymaps? would it be helpful to use tabs (and maybe even restore them as part of session restore?)
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
