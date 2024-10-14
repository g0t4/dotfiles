return {


    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",

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
                -- additional_vim_regex_highlighting = false, -- not having any effect on my regex highlighting... is that intended?
                -- doesn't look like it's doing anything right now.. no languages are marked as highlighted (nor anything else)
                -- TODO folding with treesitter?
                -- vim.wo.foldmethod = 'expr'
                -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            }
            -- TSModuleInfo shows what features (highlight, illuminate[if plugin enabled], indent, incremental_selection)
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
