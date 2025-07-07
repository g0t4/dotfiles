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
        enabled = false,
        'm4xshen/hardtime.nvim', -- tons of features, recommends, block repeated key use, etc
        dependencies = {
            "MunifTanjim/nui.nvim", -- for report float window
            "nvim-lua/plenary.nvim"
        },
        config = function()
            local version = vim.version()
            if version.major == 0 and version.minor < 10 then
                return
            end

            require("hardtime").setup({

                -- messages (via cmdline OR nvim-notify popups) =>  I find the disabled/restricted notify popups useless, the key not working / stopping is enough for me to knock it off
                notification = false, -- don't notify for disabled/restricted keys, i.e. down disabled, OR hit j repeatedly...
                hint = true, -- explicit that I want hints for now... i.e. `cw` instead of `dwi`

                timeout = 100, -- somehow actual delay seems to be like 1 or 2 seconds more than this value?!

                -- mouse considerations:
                disable_mouse = false,
                -- I missed occasional window resizing, yes I need to keymap that
                -- I like selecting with mouse and cursor in videos, its a good way to have an automatic callout
                --   and w/o mouse then selections use iterm and span across multi window layouts

                disabled_keys = {
                    -- ONLY disable arrows in normal mode, that way I can use them in INSERT mode to move up/down in the completion list, not ideal, maybe is a better way to only enable them for completion list?
                    ["<Up>"] = { "n", },
                    ["<Down>"] = { "n", },
                    ["<Left>"] = { "n", },
                    ["<Right>"] = { "n", },
                },
                --
                hints = {
                    ["ko"] = {
                        message = function()
                            return "Use `O` instead of `ko` (wes added)"
                        end,
                        length = 2,
                    },
                    --     -- https://github.com/m4xshen/hardtime.nvim/blob/main/lua/hardtime/config.lua#L3
                    --     -- appended to the default hints (see https://github.com/m4xshen/hardtime.nvim/blob/main/lua/hardtime/config.lua#L362)
                    --     --   however, if hints is empty, then it wipes out builtin hints
                    --     ["dw"] = {
                    --         message = function()
                    --             return "Use `foo` instead of `bar`"
                    --         end,
                    --         length = 2,
                    --     },
                }
                -- -- not sure why, but exit insert mode after timeout? what is the goal to learn here, to always exit insert mode? or not leave it lingering? maybe... maybe that is good so I stop using Esc Esc Esc to make sure :)
                -- force_exit_insert_mode = true, -- timeout insert mode iIUC
                -- max_insert_idle_ms = 5000 -- default 5000
            })
        end
    },

    {
        "folke/which-key.nvim",
        enabled = false,
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
