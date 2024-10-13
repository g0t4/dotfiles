return {


    {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',

        config = function()
            require 'nvim-treesitter.configs'.setup {
                ensure_installed = { "c", "lua", "python", "javascript", "typescript", "html", "css", "json", "yaml", "markdown", "vim" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
                sync_install = false,
                auto_install = true,                                                                                                       -- PRN try tree-sitter CLI too, outside of neovim
                -- ignore_install
                highlight = {
                    enable = true, -- enable for all
                    disable = {},  -- confirmed TSModuleInfo shows X for these languages
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

}
