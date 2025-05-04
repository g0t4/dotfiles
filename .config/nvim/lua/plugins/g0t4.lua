return {
    {
        -- enabled = false, -- comment out to enable
        "g0t4/illuminate.nvim",
        dir = "~/repos/github/g0t4/illuminate.nvim",
        opts = {}
    },
    {
        "g0t4/devtools.nvim",
        dir = "~/repos/github/g0t4/devtools.nvim",
        opts = {}
    },


    -- ***! NON PLUGIN CONFIG hooks... so it can depend on needed plugins w/o praying to avoid race conditions
    {
        -- FYI this is a CONFIG only plugin... it doesn't exist as a plugin in this dir:
        -- instead of praying the timing works out, express a dependency on plugins here
        --   if needed, define more virutal plugins like this with diff sets of dependencies
        --   some stuff might need to run earlier... and yet still have a few deps and not all of all of the non-plugin config
        --
        dir = "~/repos/github/g0t4/dotfiles",
        -- dir has to exist, but doesn't have to be used
        -- FYI might wanna just go all the way with this virtual plugin and have it load like a regular plugin
        --   and just point at this same dotfiles repo like the example here:
        --     https://github.com/LazyVim/LazyVim/blob/ec5981dfb1222c3bf246d9bcaa713d5cfa486fbd/lua/lazyvim/plugins/init.lua#L15
        --
        dependencies = {
            "g0t4/devtools.nvim",
        },
        config = function()
            require('localz.comment-highlights')
        end,
    },
    -- -- FYI tested that I can have a second plugin with same dir and it works too
    --    or at least doesn't blow up on lazy startup
    --
    -- {
    --     dir = "~/repos/github/g0t4/dotfiles",
    --     dependencies = {
    --      -- .. whatever diff set
    --     },
    --     config = function()
    --     end,
    -- },

}
