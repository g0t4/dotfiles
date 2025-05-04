return {
    -- {
    --     -- FYI this works good, color mappings need adjusted, I'd prefer it map to my terminal's 3bit/4bit colors and not 8bit color (IIUC it has a 256 color mapping table)... produces very dark colors currently but that can be adjusted
    --     -- idea is you have files / streams of text with CSI sequences (to color the text)
    --     -- normally if you open these you'll just see plaintext w/ CSI sequences
    --     -- so, say you want to turn the CSI sequences into actual colors over the text content
    --     -- thus you no longer see the CSI sequences too
    --
    --
    --     "m00qek/baleia.nvim",
    --     -- turn CSI sequences (in text) and translate that into colored text in a buffer
    --     -- i.e. log files with embedded CSI sequences
    --     config = function()
    --         vim.g.baleia = require("baleia").setup({})
    --
    --         -- Command to colorize the current buffer
    --         vim.api.nvim_create_user_command("BaleiaColorize", function()
    --             vim.g.baleia.once(vim.api.nvim_get_current_buf())
    --         end, { bang = true })
    --
    --         -- Command to show logs
    --         vim.api.nvim_create_user_command("BaleiaLogs", vim.g.baleia.logger.show, { bang = true })
    --     end,
    -- },

    {
        "olimorris/onedarkpro.nvim",
        priority = 1000,
        config = function()
            require("onedarkpro").setup {
                options = {
                    highlight_inactive_windows = true, -- inactive windows are lighter => also, border mechanism w/o taking up space (for horiz splits)
                    terminal_colors = false, -- use mine, close color wise but their black is nearly same as my bg
                    cursorline = true, -- also highlights the line # in the gutter, makes easier to find that way too and find relative jump offsets
                    -- transparency = true,
                },
                colors = {
                    onedark = {
                        -- override bg to not be so washed out (bright) for a dark bg... felt glowing and like it conflicted with reading the code
                        bg = "#1f2229", -- 282c34", -- this feels better (is my new terminal bg I made)
                    },
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
    --     'Mofiqul/vscode.nvim'
    -- }, -- use "vscode" ... I added this in neovim, though my other theme is fine too it seem

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
        enabled = true,
        event = { "BufRead", "InsertEnter" },
        config = function()
            require("colorizer").setup()
        end,
    },


    -- maybe:
    --  tjdevries/colorbuddy.nvim -- make it easier to define new color schemes

}
