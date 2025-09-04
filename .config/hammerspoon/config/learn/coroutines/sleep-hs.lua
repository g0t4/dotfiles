function run_async(what)
    local co = coroutine.create(what)
    coroutine.resume(co)
end

function sleep_ms(ms)
    seconds = ms / 1000
    local co = coroutine.running()
    assert(co, "sleep can only be called within a coroutine")
    hs.timer.doAfter(seconds, function()
        coroutine.resume(co)
    end)
    coroutine.yield()
end

run_async(function()
    print("before sleep")
    sleep_ms(1001)
    print("after sleep")
end)
