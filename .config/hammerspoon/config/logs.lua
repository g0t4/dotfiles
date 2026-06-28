require("config._packages")
local logger = require("devtools.logs.logger")

local M = {}

function M.hammerspoons()
    return logger.create("hammerspoons.log")
end

function M.launcher()
    return logger.create("launcher.log")
end

return M
