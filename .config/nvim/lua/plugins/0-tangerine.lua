-- article I followed:
--   https://miguelcrespo.co/posts/configuring-neovim-with-fennel/
--
-- links:
--   https://github.com/udayvir-singh/tangerine.nvim?tab=readme-ov

-- THIS IS FUCKING PISSING ME OFF... TERRIBLE GUIDES on the goddamn tangerine bullshit repo

-- TODO another direction:
-- https://github.com/Olical/nfnl?tab=readme-ov-file

-- TODO link into init.lua and/or lazy to load and test this
--  why is there all this nonsense about needing to load it before lazy? is this some assumption I want everything to pass through it, or ?!

local pack = "lazy"
--
-- local function bootstrap(url, ref)
--     local name = url:gsub(".*/", "")
--     local path
--
--     path = vim.fn.stdpath("data") .. "/lazy/" .. name
--     vim.opt.rtp:prepend(path)
--
--     if vim.fn.isdirectory(path) == 0 then
--         print(name .. ": installing in data dir...")
--
--         vim.fn.system { "git", "clone", url, path }
--         if ref then
--             vim.fn.system { "git", "-C", path, "checkout", ref }
--         end
--
--         vim.cmd "redraw"
--         print(name .. ": finished installing")
--     end
-- end
--
-- -- TODO how do I wanna go about updates?
-- --  honestly I'd prefer if lazy could handle install/updates?! why not? I can load tangerine as a first plugin
-- bootstrap("https://github.com/udayvir-singh/tangerine.nvim", "v2.9")
--
-- -- TODO try hibiscus macros (i.e. set!)
-- -- bootstrap("https://github.com/udayvir-singh/hibiscus.nvim")
--
-- -- FYI as needed I will re-arrange lua code to run it through fnl to make it available one or both ways (fnl => lua, lua => fnl) as the need arises and not prematurely
-- --   I might end up hating using fennel so don't jump the gun
--
-- require "tangerine".setup {}

return {
    {
        "udayvir-singh/tangerine.nvim",
        -- dependencies = { "Olical/aniseed" },
        config = function()
            require("tangerine").setup {
                -- target = vim.fn.stdpath [[data]] .. "/tangerine",
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
