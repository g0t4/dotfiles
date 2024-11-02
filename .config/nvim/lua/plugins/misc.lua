return {
    {
        "rcarriga/nvim-notify",
        config = function()
            -- FYI I will probably hate this with hardline... maybe turn off hardline warns then?
            vim.notify = require("notify")

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
    {
        "g0t4/test-nvim",
        dir = "~/repos/github/g0t4/test-nvim", -- seems to take precedence over name => URL mapping
        config = function()
            -- without defer, the notify in my plugin doesn't work..
            -- TODO migrate to vim.notify so I don't need the explicit dependency, just for testing anyways
            -- vim.defer_fn(function()
            require("test-nvim")
            -- end, 100)
        end,
        dependencies = {
            "rcarriga/nvim-notify",
        },
    },

    -- {
    --     "https://github.com/folke/noice.nvim"
    --     -- TODO TRY THIS
    --     -- command output in regular buffer!!! YES?! i.e. `:highlight` or `:nmap` => not the stupid output pager thingy you cannot leave open
    --     -- many others, not sure I want all mods
    -- },

}
