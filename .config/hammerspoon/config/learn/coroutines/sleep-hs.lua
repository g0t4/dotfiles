function run_async(what)
    local co = coroutine.create(what)
    coroutine.resume(co)
end

function sleep_ms(ms)
    seconds = ms / 1000
    local _co = coroutine.running()
    hs.timer.doAfter(seconds, function()
        coroutine.resume(_co)
    end)
    coroutine.yield()
end

run_async(function()
    print("before sleep")
    sleep_ms(1001)
    print("after sleep")
end)
