return {
    {
        -- FYI provides syntax highlighting for applescript (that's it):
        "vim-scripts/applescript.vim",
        -- *** DO NOT LAZY LOAD THIS... will not map filetype NOR will sytanx be registered (has to happen early during init)
        config = function()
            -- FYI I am only using the plugin loader so I can get the syntax file, I could easily copy that over and not use plugins for this
            -- register filetype for applescript files
            vim.filetype.add({
                extension = {
                    applescript = "applescript",
                },
            })
            -- alternative for filetype reg:
            -- vim.cmd [[au BufRead,BufNewFile *.applescript set filetype=applescript]]

            -- then syntax is loaded automatically from:
            --     applescript.vim/syntax/applescript.vim
        end

    }
}
