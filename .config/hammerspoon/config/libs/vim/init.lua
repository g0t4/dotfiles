-- vim.* functions for hammerspoon too!

-- I hate working with what amounts to two different stdlibs, why not use the best of both...
-- and/or whatever I am familiar with!


-- FYI here is where neovim creates the _G.vim global
--   https://github.com/neovim/neovim/blob/master/src/gen/preload_nlua.lua#L12
--   which imports shared as starting point:
--     https://github.com/neovim/neovim/blob/master/runtime/lua/vim/shared.lua
local vim = require("config.libs.vim.shared")
vim.iter  = require("config.libs.vim.iter")
vim.inspect = require("config.libs.vim.inspect")
-- TODO add more things I love from:  https://github.com/neovim/neovim/blob/master/runtime/lua/vim



return vim
