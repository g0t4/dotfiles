return {


    {
        'm4xshen/hardtime.nvim', -- tons of features, recommends, block repeated key use, etc
        requires = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
        config = function()
            require("hardtime").setup()
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
