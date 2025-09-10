local uv = require("luv")

function run_async(what)
    local co = coroutine.create(what)
    coroutine.resume(co)
end

function sleep_ms(duration)
    local co = coroutine.running()
    assert(co, "sleep can only be called within a coroutine")
    uv.new_timer():start(duration, 0, function(timer)
        local ok, err = coroutine.resume(co)
        if not ok then
            print("sleep_ms: resume failed after timer elapsed: " .. tostring(err))
        end
    end)
    coroutine.yield()
end

run_async(function()
    print("before sleep")
    sleep_ms(1000)
    print("after sleep")
end)

uv.run()
