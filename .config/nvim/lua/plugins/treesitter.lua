return {


    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",

        event = require('event-triggers').buffer_with_content_events,

        config = function()
            require 'nvim-treesitter.configs'.setup {
                ensure_installed = { "c", "lua", "python", "javascript", "typescript", "html", "css", "json", "yaml", "markdown", "vim" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
                sync_install = false,
                auto_install = true,                                                                                                       -- auto install on entering buffer (must have tree-sitter CLI, IIUC)
                -- ignore_install
                highlight = {
                    enable = true, -- enable for all
                    disable = {},  -- confirmed TSModuleInfo shows X for these languages
                },
                indent = {
                    enable = true,
                    disable = {},
                },
                -- FYI doesn't seem to be a "fold/ing" enable/disable config section
                incremental_selection = {
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
