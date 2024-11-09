-- window keymaps
local default_options = { noremap = true, silent = true }

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
