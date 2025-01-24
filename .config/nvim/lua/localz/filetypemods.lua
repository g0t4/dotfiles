vim.cmd [[

    " SVG
    "autocmd FileType svg echo "SVG opened"
    autocmd FileType svg set wrap




    " markdown
    autocmd FileType md set wrap


]]

vim.api.nvim_create_autocmd("FileType", {
    pattern = "editorconfig",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

-- set commentstring for json files (i.e. coc-settings.json), obviously not all json readers can handle comments so be careful
vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
        vim.bo.commentstring = "// %s" -- %s is original text
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "graphql",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

-- ~/.editrc
vim.api.nvim_create_autocmd("FileType", {
    pattern = "editrc",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
        -- PRN do I want these here too:
        -- vim.bo.shiftwidth = 4
        -- vim.bo.tabstop = 4
    end,
})
