vim.cmd [[

    " SVG
    "autocmd FileType svg echo "SVG opened"
    autocmd FileType svg set wrap




    " markdown
    autocmd FileType md set wrap


]]

-- set commentstring for json files (i.e. coc-settings.json), obviously not all json readers can handle comments so be careful
vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
        vim.bo.commentstring = "// %s" -- %s is original text
    end,
})
