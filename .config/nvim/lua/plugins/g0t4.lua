return {

    {
        -- enabled = false, -- comment out to enable
        "g0t4/illuminate.nvim",
        dir = "~/repos/github/g0t4/illuminate.nvim",
        opts = {}
    },

    {
        -- enabled  = false, -- comment out to enable
        "g0t4/devtools.nvim",
        dir = "~/repos/github/g0t4/devtools.nvim",
        -- opts = {}
        config = function()
            require("devtools").setup {}
            local messages = require "devtools.messages"

            -- open messages automatically for testing
            vim.schedule(function()
                messages.ensure_open()
            end)
        end

    },

}
