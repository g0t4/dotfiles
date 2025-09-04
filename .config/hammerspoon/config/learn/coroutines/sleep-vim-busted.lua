-- function run_async(what)
--     local co = coroutine.create(what)
--     coroutine.resume(co)
--     return co
-- end

function sleep(duration)
    local _co = coroutine.running()
    vim.defer_fn(function(timer)
        coroutine.resume(_co)
    end, duration)
    coroutine.yield()
end

it("test sleep", function()
    -- busted/plenary uses coroutines
    --  so I don't need to create one w/ run_async
    print("before sleep")
    sleep(1000)
    print("after sleep")
end)
