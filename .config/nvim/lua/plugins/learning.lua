return {

    -- TODO make a plugin that tracks which keys you use and has a report or reminds you when not using new keys you want to be learning...
    -- i.e. right now: `zz` daily `zt/zb` weekly
    --     H/M/L normal mode weekly
    --     Ctrl+U/D daily
    --     track when I sequentially move up x lines and should've used page up/down instead? ...  i.e. 10+ lines (or half of lines var) in a row
    --     gg=G monthly
    --
    --

    {
        'm4xshen/hardtime.nvim', -- tons of features, recommends, block repeated key use, etc
        requires = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
        config = function()
            local version = vim.version()
            if version.major == 0 and version.minor < 10 then
                return
            end

            require("hardtime").setup({

                disabled_keys = {
                    -- ONLY disable arrows in normal mode, that way I can use them in INSERT mode to move up/down in the completion list, not ideal, maybe is a better way to only enable them for completion list?
                    ["<Up>"] = { "n", },
                    ["<Down>"] = { "n", },
                    ["<Left>"] = { "n", },
                    ["<Right>"] = { "n", },
                },

            })
        end
    },

    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup {
                delay = 1000, -- before open (ms)

                plugins = {
                    presets = {
                        motions = true, -- show help for motions too => type `d` and wait (although it doesn't show d again for line?)
                    }
                }

                -- default configures keymap triggers for every mode
                --   so when you pause mid key combo, it pops open... not if you rapidly enter the key combo
                --   also gives you time to look and pick w/o timeout on keys (IIGC timeoutlen limits this)
                --   would be good to increase delay me thinks, lets wait and see though
                --        delay = function(ctx)
                --             return ctx.plugin and 0 or 200
                --           end,

                --
                --   pulls desc attr of each map, so set those!
                -- opts.triggers includes { "<auto>", mode = "nixsotc" },
                -- optional - for icons - mini.icons or nvim-web-devicons
            }
        end
    }



}
