return {

    -- {
    --     'Mofiqul/vscode.nvim'
    -- }, -- use "vscode" ... I added this in neovim, though my other theme is fine too it seem

    {
        -- FYI onedarkpro supports this OOB so I will try it
        "nvim-lualine/lualine.nvim",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            function StatusLine_Line_Column()
                return "L:" .. vim.fn.line(".") .. "/C:" .. vim.fn.col(".")
            end

            function StatusLine_Line()
                return "Line " .. vim.fn.line(".")
            end

            function StatusLine_Column()
                return "Col " .. vim.fn.col(".")
            end

            require("lualine").setup {
                -- default: https://github.com/nvim-lualine/lualine.nvim#default-configuration
                -- options = {
                --     theme = "codedark",
                --     section_separators = { "", "" },
                --     component_separators = { "", "" },
                --     globalstatus  -- only one status line? hrm... might work now that I have inactive windows dimmed in onedarkpro theme
                -- },
                -- FYI =>    :lua print(vim.inspect(require('lualine').get_config()))
                sections = {
                    -- commandline shows mode already so why put it here too? plus lualine has color changes
                    -- lualine_a = { 'buffers' }, -- TODO "buffers" looks interesting! shows tabs for each file... might be what I've been wanting?
                    lualine_a = { '' },
                    lualine_b = { { -- FYI wrap in {} to customize component options
                        --   https://github.com/nvim-lualine/lualine.nvim#filename-component-options
                        "filename",
                        path = 1, -- 1 = relative path, 4 = filename+parentdir sounds interesting
                        -- relative path, 4 filename+parentdir sounds interesting
                    } },          -- filename includes modified
                    lualine_c = { "filetype" },
                    lualine_x = { "GetStatusLineCopilot" },
                    lualine_y = { StatusLine_Line, StatusLine_Column, "progress" },
                    lualine_z = { '' },
                },
                inactive_sections = {
                    lualine_a = {},             -- default ""
                    lualine_b = { "filename" }, -- default ""
                    lualine_c = { "" },         -- default "filename"
                    lualine_x = { "location" }, -- default "location"
                    lualine_y = {},             -- default ""
                    lualine_z = {},             -- default ""
                },
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
                    terminal_colors = false,           -- use mine, close color wise but their black is nearly same as my bg
                    cursorline = true,                 -- also highlights the line # in the gutter, makes easier to find that way too and find relative jump offsets
                    -- transparency = true,
                },

            }

            -- FYI get colors =>    :lua print(vim.inspect(require("onedarkpro.helpers").get_colors()))

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
