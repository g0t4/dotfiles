require("config._packages")
local logger = require("devtools.logs.logger")

local M = {}

function M.hammerspoons()
    return logger.create("hammerspoons.log")
end

return M
