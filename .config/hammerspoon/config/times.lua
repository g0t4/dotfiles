local socket = require("socket")
-- luarocks install luasocket
local M = {}

local start_time = socket.gettime()

function M.set_start_time()
    start_time = socket.gettime()
end

function M.print_elapsed(message)
    local elapsed_time = socket.gettime() - start_time
    print(string.format("%s: %.6f seconds", message, elapsed_time))
end

return M

-- FYI ONLY ONE start time at a time... NBD right now, works fine for what I needed
-- USAGE:
-- local t = require("config.times")
-- t.set_start_time() -- optional cuz require sets start time too
-- foo()
-- t.print_elapsed("foo")
