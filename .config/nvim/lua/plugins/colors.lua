return {

    -- {
    --     'Mofiqul/vscode.nvim'
    -- }, -- use "vscode" ... I added this in neovim, though my other theme is fine too it seem
    {
        -- FYI onedarkpro supports this OOB so I will try it
        "nvim-lualine/lualine.nvim",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require("lualine").setup {
                -- options = {
                --     theme = "codedark",
                --     section_separators = { "", "" },
                --     component_separators = { "", "" },
                -- },
                -- TODO port my copilot indicator
                -- sections = {
                --     lualine_a = { "mode" },
                --     lualine_b = { "branch" },
                --     lualine_c = { "filename" },
                --     lualine_x = { "encoding", "fileformat", "filetype" },
                --     lualine_y = { "progress" },
                --     lualine_z = { "location" },
                -- },
                -- inactive_sections = {
                --     lualine_a = {},
                --     lualine_b = {},
                --     lualine_c = { "filename" },
                --     lualine_x = { "location" },
                --     lualine_y = {},
                --     lualine_z = {},
                -- },
            }
        end,
    },

    {
        "olimorris/onedarkpro.nvim",
        priority = 1000,
        config = function()
            require("onedarkpro").setup {
                options = {
                    highlight_inactive_windows = true, -- inactive windows are lighter => also, border mechanism w/o taking up space (for horiz splits)
                    terminal_colors = false, -- use mine, close color wise but their black is nearly same as my bg
                    cursorline = true, -- ok I'll give this a try
                },
            }

            vim.cmd [[
                colorscheme onedark
                set termguicolors
            ]]
        end,
    },

    -- {
    --     -- I like this theme, could modify it to my liking later when I figure out highlight issues
    --     -- https://github.com/navarasu/onedark.nvim
    --     'navarasu/onedark.nvim',
    --     config = function()
    --         require('onedark').setup {
    --             style = 'darker', -- or 'onelight'
    --         }
    --         require('onedark').load()
    --     end
    -- },

    -- FYI PROVEN vscode scheme looks good enough:
    -- {
    --     'tomasiser/vim-code-dark', -- use "codedark" from my vimrc
    --     priority = 1000,           -- highest to set this first, including termguicolors early too ( random errors tie back to race conditioon on setting termguicolors)
    --     config = function()
    --         vim.cmd [[
    --             colorscheme codedark
    --             set termguicolors
    --             ]]
    --     end
    -- },

    {
        "norcalli/nvim-colorizer.lua", -- colorize hex codes, etc
        event = require("event-triggers").buffer_with_content_events,
        config = function()
            require("colorizer").setup()
        end,
    },


    -- maybe:
    --  tjdevries/colorbuddy.nvim -- make it easier to define new color schemes

}
