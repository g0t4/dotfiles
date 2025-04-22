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

                -- vimrc = nvim_dir .. "/init.fnl", -- I'd need to re-engineer loading tangerine me thinks to use it for init.fnl... and I don't give a F about doing that any time soon

                -- source = nvim_dir .. "/fnl", -- default

                -- puts files into ~/.local/share/nvim/tangerine (sounds good to me!)
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
