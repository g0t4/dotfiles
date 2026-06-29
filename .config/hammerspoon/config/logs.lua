require("config._packages")
local logger = require("devtools.logs.logger")

local M = {}

function M.hammerspoons()
    return logger.create("hammerspoons.log")
end

function M.km_run_lua()
    return logger.create("km_run_lua.log")
end

function M.launcher()
    return logger.create("launcher.log")
end

return M
