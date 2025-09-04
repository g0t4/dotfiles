function run_async(what)
    local co = coroutine.create(what)
    coroutine.resume(co)
end

function sleep(duration)
    local _co = coroutine.running()
    hs.timer.doAfter(duration, function()
        coroutine.resume(_co)
    end)
    coroutine.yield()
end

run_async(function()
    print("before sleep")
    sleep(1000)
    print("after sleep")
end)
