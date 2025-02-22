





local co_outer = coroutine.create(function()
    require "socket"
    local socket = require 'socket'
    socket.sleep(1)
    print('foo')
    --
    -- function sleep(sec)
    --     socket.select(nil, nil, sec)
    -- end
    --
    -- sleep(1)
end)
coroutine.resume(co_outer)

