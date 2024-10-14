return {


    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",

        config = function()
            -- nvim-treesitter[lua]: Could not create tree-sitter-lua-tmp
            -- mkdir: tree-sitter-lua-tmp: File exists
            -- TODO when do I wanna do this part of tree sitter? this keeps running the same install sync step on every load...  definitely don't want that here
            --
            require 'nvim-treesitter.configs'.setup {
                ensure_installed = { "c", "lua", "python", "javascript", "typescript", "html", "css", "json", "yaml", "markdown", "vim" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
                sync_install = false,
                -- auto_install = true,                                                                                                       -- PRN try tree-sitter CLI too, outside of neovim
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
            }
            -- TSModuleInfo shows what features (highlight, illuminate[if plugin enabled], indent, incremental_selection)
        end
    },

    {
        'nvim-treesitter/playground',
        dependencies = {
            { 'nvim-treesitter/nvim-treesitter' },
        },
        cmd = {
            'TSPlaygroundToggle',
            'TSHighlightCapturesUnderCursor',
            -- TODO others?
        }, -- lazy load on command used
        config = function()
            require('nvim-treesitter.configs').setup()
        end
    },

    -- highlight just word under cursor:
    {
        "RRethy/vim-illuminate",
        event = "CursorHold",
        dependencies = {
            { 'nvim-treesitter/nvim-treesitter' },
        },
    }, 
    -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column
    --    sadly, not the current selection (https://github.com/RRethy/vim-illuminate/issues/196), I should write this plugin
    --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
    --    customizing:
    --      hi def IlluminatedWordText gui=underline
    --      hi def IlluminatedWordRead gui=underline
    --      hi def IlluminatedWordWrite gui=underline

}
