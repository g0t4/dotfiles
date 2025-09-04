local uv = require("luv")

function run_async(what)
    local co = coroutine.create(what)
    coroutine.resume(co)
end

function sleep_ms(duration)
    local _co = coroutine.running()
    uv.new_timer():start(duration, 0, function(timer)
        -- timer:stop()
        coroutine.resume(_co)
    end)
    coroutine.yield()
end

run_async(function()
    print("before sleep")
    sleep_ms(1000)
    print("after sleep")
end)

uv.run()
