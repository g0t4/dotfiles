-- ** neovide **
-- -- no.. just no...
-- if vim.g.neovide then
--     vim.g.neovide_cursor_animation_length = 0
--     vim.g.neovide_scroll_animation_length = 0
--     -- FYI paste is broken OOB w/ CMD+V
--     -- ALSO, need to disable my scroll plugin that adds the animation for nvim
-- end

return {

    -- *** TESTING ***
    -- TODO try testing, instead of / in addition to Plenary
    -- {
    --     "nvim-neotest/neotest",
    -- },

    {
        -- FYI use `:Notifications` to see history of notifications
        "rcarriga/nvim-notify",
        -- enabled = false,
        config = function()
            -- actually this was useful-ish for hardtime cuz I would see the notices... but I hated it on everything else + disappearing messages are yuck (that I have to lookup special) AND often I want them gone (when recording) and I have to wait 5 sec
            --   TODO learn commands and/or bind keymaps
            vim.notify = require("notify") -- route all notifications through this (plugins can use vim.notify none the wiser)
            require("notify").setup({
                -- stages = "fade",
                --
                -- wtf... turning on wrapped/wrapped-default ignores newlines \n ... UGH
                --    without this, long strings just run off the screen..
                --    why can't I have new line + wrap... and why can't I have wrap based on width of screen (set max to screen width and not force a hard coded amount... UGH)
                --    can set render on a per notify call basis, but it doesn't use max_width on per notify call so its a mess of the default max_width of like 20
                --    OK for now just pass "wrapped-compact" on per notify call and that looks good enough (still has new line issue but whatever)
                -- render = "wrapped-default",
                -- max_width = 80,
            })
        end,
    },

    -- {
    --     "https://github.com/folke/noice.nvim",
    --     config = function()
    --         require("noice").setup({
    --         })
    --     end,
    --     dependencies = {
    --         "rcarriga/nvim-notify",
    --         "MunifTanjim/nui.nvim",
    --     },
    --     -- TODO TRY THIS
    --     -- command output in regular buffer!!! YES?! i.e. `:highlight` or `:nmap` => not the stupid output pager thingy you cannot leave open
    --     -- many others, not sure I want all mods
    -- },

}
