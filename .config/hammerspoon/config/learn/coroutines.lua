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

local job1 = coroutine.create(function()
    print('job1 started: ')
    local result1 = coroutine.yield(slowSearch)
    print('job1 result1: ', result1)
    local result2 = coroutine.yield(slowSearch)
    print('job1 result2:', result2)
end)


local job2 = coroutine.create(function()
    print('job2 started: ')
    local result1 = coroutine.yield(slowSearch)
    print('job2 result1: ', result1)
    local result2 = coroutine.yield(slowSearch)
    print('job2 result2:', result2)
end)

-- PRN add job queue (push all work here, including new coroutines that call a yielded func... and maps the result back to the original coroutine... would need to yield though to avoid deadlocks? lock between result and resume coroutuine?
local queue = {}

table.insert(queue, job1)


-- todo loop until done... can always yield nothing to effectively say I am giving up CPU for someone else
-- coroutine.status()
local ok, asyncFunc = coroutine.resume(job1)
-- if (asyncFunc ~= nil) then
asyncFunc(function(...)
    print("fuck")
    coroutine.resume(job1, ...)
end)
-- end




-- FYI blocking sleep:
-- require "socket"
-- local socket = require 'socket'
-- socket.sleep(1)
