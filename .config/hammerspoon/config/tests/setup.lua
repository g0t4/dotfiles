local M = {}

function M.dump_package_paths()
    local paths = {}
    for path in string.gmatch(package.path, "[^;]+") do
        print(path)
        table.insert(paths, path)
    end
    print()
end

local function add_plugin_to_package_path(plugin_path)
    package.path = package.path .. ";" .. plugin_path .. "?.lua"
    package.path = package.path .. ";" .. plugin_path .. "?/init.lua"
end

local function add_rxlua_to_package_path()
    if vim == nil then
        -- for lua/busted/hs rx comes from rxlua pkg in luarocks and it all works OOB
        return
    end

    -- only add if using vim for running tests (plenary)
    -- THIS IS NOT A PRIMARY use case it's just a nice to have
    add_plugin_to_package_path(vim.fn.stdpath("data") .. "/lazy/RxLua/")
    -- other possibilities:
    --   -- vim.opt.runtimepath:append("~/.local/share/nvim/lazy/rxlua")
end

local function add_devtools_to_package_path()
    add_plugin_to_package_path(os.getenv("HOME") .. "/repos/github/g0t4/devtools.nvim/lua/")
end

-- FYI two separate runners:
-- - busted (via luarocks) => already has luarocks setup and working
--   lua 5.4 via hs
-- - nvim plenary runner => does not have things like rxlua (or other luarocks pkgs avail OOB)
--   I supposed I could modify it to do so in my nvim config
--   but then nvim is also lua 5.1
-- - hammerspoon itself
--   yet another runtime (for prod code in my case)
-- * KEEP IN MIND that each one may need different mods to package path
-- - GOOD test case is to add `require('rx')` to a test file... (remove when done)

-- immediately modify package path on import (require)
add_devtools_to_package_path()
add_rxlua_to_package_path()

return M
