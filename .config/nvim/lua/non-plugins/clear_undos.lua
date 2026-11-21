vim.api.nvim_create_user_command("ClearUndos", function()
    if #vim.fn.undotree().entries == 0 then
        print("Undo history is already empty")
        return
    end

    local buf = vim.bo
    local levels = buf.undolevels
    local modified = buf.modified
    buf.undolevels = -1
    -- :help clear-undo requires an edit. An empty splice keeps the text intact.
    local ok, err = pcall(vim.api.nvim_buf_set_text, 0, 0, 0, 0, 0, {})
    buf.undolevels = levels
    if not ok then error(err) end
    buf.modified = modified
    print("Cleared undo history for this buffer")
end, { desc = "Clear the current buffer's undo history" })

vim.keymap.set("n", "<leader>cu", "<Cmd>ClearUndos<CR>", { desc = "Clear undos" })
