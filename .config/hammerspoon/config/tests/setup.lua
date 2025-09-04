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
    add_plugin_to_package_path(vim.fn.stdpath("data") .. "/lazy/RxLua/")
    -- other possibilities:
    --   -- vim.opt.runtimepath:append("~/.local/share/nvim/lazy/rxlua")
end

local function add_devtools_to_package_path()
    add_plugin_to_package_path(os.getenv("HOME") .. "/repos/github/g0t4/devtools.nvim/lua/")
end

-- immediately modify package path on import (require)
add_devtools_to_package_path()
add_rxlua_to_package_path()

return M
