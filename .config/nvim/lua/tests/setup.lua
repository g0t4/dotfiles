local M = {}

local function add_plugin_to_package_path(for_package_path, for_rtp)
    package.path = package.path .. ";" .. for_package_path .. "?.lua"
    package.path = package.path .. ";" .. for_package_path .. "?/init.lua"

    -- FYI added this for my traces fix tests that use RTP instead of package.path... basically package.path is not the only spot that is modified by plugin loaders (i.e. lazy)
    if for_rtp ~= nil then
        vim.opt.runtimepath:append(for_rtp)
    end
end

local function add_rxlua_to_package_path()
    add_plugin_to_package_path(
    -- FYI IIRC rxlua has diff layout hence no /lua on package.path mod:
        vim.fn.stdpath("data") .. "/lazy/RxLua/",
        vim.fn.stdpath("data") .. "/lazy/RxLua/"
    )
    -- FYI confirm path used in your neovim runtime `:= vim.o.rtp` and `:= package.path` and then set similar values here
    --   IOTW does a given package have ./lua rootmost dir or not for package.path mod
end

local function add_devtools_to_package_path()
    add_plugin_to_package_path(
        os.getenv("HOME") .. "/repos/github/g0t4/devtools.nvim/lua/",
        os.getenv("HOME") .. "/repos/github/g0t4/devtools.nvim"
    )
end

local function add_ask_openai_to_package_path()
    add_plugin_to_package_path(
        os.getenv("HOME") .. "/repos/github/g0t4/ask-openai.nvim/lua/",
        os.getenv("HOME") .. "/repos/github/g0t4/ask-openai.nvim"
    )
end

-- TODO MERGE WITH OTHER similar test setup modules already in dotfiles? and move it.. right now this is starting out in code notes only

function M.modify_package_path()
    add_devtools_to_package_path()
    add_ask_openai_to_package_path()
    add_rxlua_to_package_path()
end

return M
