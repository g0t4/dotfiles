-- article I followed:
--   https://miguelcrespo.co/posts/configuring-neovim-with-fennel/
-- links:
--   https://github.com/udayvir-singh/tangerine.nvim?tab=readme-ov

-- -- FYI as needed I will re-arrange lua code to run it through fnl to make it available one or both ways (fnl => lua, lua => fnl) as the need arises and not prematurely
-- --   I might end up hating using fennel so don't jump the gun
--
return {
    {
        -- FYI I just put this together myself and its working so far, mostly guess work
        --   right now it compiles to lua on save, which is fine
        --
        "udayvir-singh/tangerine.nvim",
        config = function()
            require("tangerine").setup {
                -- config defaults:
                --    https://github.com/udayvir-singh/tangerine.nvim#default-config

                -- ok this puts files into ~/.local/share/nvim/tangerine (sounds good to me!)
                target = vim.fn.stdpath [[data]] .. "/tangerine",
                -- rtpdirs = {
                --     "fnl",
                --     -- "$HOME/mydir" -- absolute paths are also supported
                -- },
                compiler = {
                    -- verbose = true, -- ??
                    hooks = { "onsave", "oninit" },
                },
            }
        end,
        lazy = false,
        priority = 1000,
    }

}

-- TODO:
-- brew install fnlfmt
-- https://fennel-lang.org/see  -- lua => fnl
-- LS front:
--   ouch apparently fennel-language-server doesn't support vim APIs (yet?)
--   https://git.sr.ht/~xerool/fennel-ls - not sure if it does or not, written in fennel
