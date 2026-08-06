local M = {}

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

local function add_ask_openai_to_package_path()
    add_plugin_to_package_path(os.getenv("HOME") .. "/repos/github/g0t4/ask-openai.nvim/lua/")
end

-- TODO MERGE WITH OTHER similar test setup modules already in dotfiles? and move it.. right now this is starting out in code notes only

function M.modify_package_path()
    add_devtools_to_package_path()
    add_ask_openai_to_package_path()
    add_rxlua_to_package_path()
end

return M
