-- function run_async(what)
--     local co = coroutine.create(what)
--     coroutine.resume(co)
--     return co
-- end

function sleep_ms(duration)
    local co = coroutine.running()
    assert(co, "sleep can only be called within a coroutine")
    vim.defer_fn(function()
        coroutine.resume(co)
    end, duration)
    coroutine.yield()
end

it("test sleep", function()
    -- busted/plenary uses coroutines
    --  so I don't need to create one w/ run_async
    print("before sleep")
    sleep_ms(1000)
    print("after sleep")
end)
