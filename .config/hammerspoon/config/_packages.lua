-- require("config.tests.setup")
local function add_plugin_to_package_path(plugin_path)
    package.path = package.path .. ";" .. plugin_path .. "?.lua"
    package.path = package.path .. ";" .. plugin_path .. "?/init.lua"
end

-- FYI attempt here is to reuse some of devtools.nvim in hammerspoon
-- TODO move this logic for devtools to path to early start of hammerspoon process?
--  TODO or just split it into its own module then rely on it here and in other spots where I need it?

local function add_devtools_to_package_path()
    add_plugin_to_package_path(os.getenv("HOME") .. "/repos/github/g0t4/devtools.nvim/lua/")
end

add_devtools_to_package_path()

