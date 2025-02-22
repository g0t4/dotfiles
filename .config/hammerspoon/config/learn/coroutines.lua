-- function wrap(func, callback)
--     local co = coroutine.create(function()
--         func(callback)
--         coroutine.yield()
--     end)
-- end

local function slowSearch(callback)
    -- simulate slow search
    hs.timer.doAfter(1, function() callback("surprise butt sex") end):start()
end

local co_outer = coroutine.create(function()
    print('outer starts: ')
    local result = coroutine.yield(slowSearch)
    print('outer result: ', result)
end)
-- todo loop until done... can always yield nothing to effectively say I am giving up CPU for someone else
-- coroutine.status()
local ok, asyncFunc = coroutine.resume(co_outer)
-- if (asyncFunc ~= nil) then
asyncFunc(function(...)
    print("fuck")
    coroutine.resume(co_outer, ...)
end)
-- end




-- FYI blocking sleep:
-- require "socket"
-- local socket = require 'socket'
-- socket.sleep(1)
