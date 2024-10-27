return {


    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",

        event = require('event-triggers').buffer_with_content_events,

        config = function()
            -- TODO go back to yellow after I get migrated, leave orange on TODO as visual reminder as I keep my legacy highlighters loaded for all other languages not done yet
            vim.api.nvim_set_hl(0, '@comment_todo', { fg = '#FF8800' })                                   -- TODO test
            vim.api.nvim_set_hl(0, '@comment_todo_bang', { bg = '#FF8800', fg = "#1f1f1f", bold = true }) -- TODO! test
            -- -- yellow TODOs:
            -- vim.api.nvim_set_hl(0, '@comment_todo', { fg = '#ffcc00' })                                         -- TODO test
            -- vim.api.nvim_set_hl(0, '@comment_todo_bang', { bg = '#ffcc00', fg = "#1f1f1f", bold = true })       -- TODO! test
            --
            vim.api.nvim_set_hl(0, '@comment_asterisks', { fg = '#ff00c3' })                                    -- *** test
            vim.api.nvim_set_hl(0, '@comment_asterisks_bang', { bg = '#ff00c3', fg = "#1f1f1f", bold = true })  -- ***! test
            vim.api.nvim_set_hl(0, '@comment_prn', { fg = "#27AE60" })                                          -- PRN test
            vim.api.nvim_set_hl(0, '@comment_prn_bang', { bg = "#27AE60", fg = "#1f1f1f", bold = true })        -- PRN! test
            vim.api.nvim_set_hl(0, '@comment_single_bang', { fg = "#cc0000" })                                  -- ! test
            vim.api.nvim_set_hl(0, '@comment_triple_bang', { bg = "#cc0000", fg = "#ffffff", bold = true })     -- !!! test
            vim.api.nvim_set_hl(0, '@comment_single_question', { fg = "#3498DB" })                              -- ? test
            vim.api.nvim_set_hl(0, '@comment_triple_question', { bg = "#3498DB", fg = "#1f1f1f", bold = true }) -- ??? test

            require 'nvim-treesitter.configs'.setup {
                ensure_installed = { "c", "lua", "python", "javascript", "typescript", "html", "css", "json", "yaml", "markdown", "vim" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
                sync_install = false,
                auto_install = true,                                                                                                       -- auto install on entering buffer (must have tree-sitter CLI, IIUC)
                -- ignore_install
                highlight = {
                    enable = true, -- doesn't seem to turn it off, is treesitter initilized b/c of some other plugin first and thus my config here isn't applied?
                    -- disable = {},  -- confirmed TSModuleInfo shows X for these languages
                    -- additional_vim_regex_highlighting = true, -- true OR list of languages... I can't get this to change anything with my custom sytnax highlights, maybe this is smth else enable/disable?

                    -- custom_captures = {
                    --   -- IIUC I only need this if I want to link to another existing hl group (ie in a theme)
                    --     ["comment_todo"] = "TodoComment",
                    -- },
                },
                indent = {
                    enable = true,
                    disable = {},
                },
                -- FYI doesn't seem to be a "fold/ing" enable/disable config section
                incremental_selection = {
                    -- similar to Ctrl+W in jetbrains IDEs
                    enable = true,
                    keymaps = {
                        init_selection = 'gnn',    -- Start selection
                        node_incremental = 'grn',  -- Expand to the next node
                        scope_incremental = 'grc', -- Expand to the next scope
                        node_decremental = 'grm',  -- Shrink selection
                    },
                },
            }
            -- TSModuleInfo shows what features (highlight, illuminate[if plugin enabled], indent, incremental_selection), not folding?
        end,
        init = function()
            -- https://neovim.io/doc/user/fold.html (FYI can use other methods like indent, syntax, manual, etc... for now I will try ts based)
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

            vim.o.foldenable = false -- no autofolding, just manual after open file
        end
    },

    -- FYI :Inspect breaks down highlights into: Treesitter, Syntax, Extmarks... very useful
    -- -- nvim has :Inspect, :InspectTree (:TSPlayground), :EditQuery (nvim 0.10) builtin now
    -- {
    --     'nvim-treesitter/playground',
    --     dependencies = {
    --         { 'nvim-treesitter/nvim-treesitter' },
    --     },
    --     cmd = {
    --         'TSPlaygroundToggle',
    --         'TSHighlightCapturesUnderCursor',
    --     }, -- lazy load on command used
    --     config = function()
    --         require('nvim-treesitter.configs').setup()
    --     end
    -- },

    {
        -- highlight word under cursor, other occurrences
        "RRethy/vim-illuminate",
        event = "CursorHold",
        dependencies = {
            { 'nvim-treesitter/nvim-treesitter' },
        },
        -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column (several providers actually: treesitter, LSP, regex by default)
        --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
        --    customizing:
        --      hi def IlluminatedWordText gui=underline
        --      hi def IlluminatedWordRead gui=underline
        --      hi def IlluminatedWordWrite gui=underline
    },

}
