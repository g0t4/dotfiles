function runner_tramp(main)
    local co = coroutine.create(main)
    local success, what = coroutine.resume(co)
    if not success then
        print("FAILURE IN runner_tramp: " .. vim.inspect(what))
    end
    -- wrap co into a thread and start it
end

function api_crunch_data(callback)
    print("2. start crunch data")
    vim.defer_fn(function()
        print("3. end crunch data")
        callback({ 1, 5, 10 })
        print("?. after callback - test finishes before this b/c callback resumes and finishes it... this may keep running if test runner doesn't stop first")
    end, 100)
end

function callbacker(call_this, ...)
    --- cooperative sleeper (non-blocking)
    local co, is_main = coroutine.running()

    local captured_args = nil -- TODO only need this for a callbacker equivalent
    call_this(function(...)
        captured_args = ...
        coroutine.resume(co)
    end, ...)

    coroutine.yield()
    print("    3. callbacker captured args:", vim.inspect(captured_args))
    return captured_args
end

runner_tramp(function()
    print("1. start building report.... before crunch_data called")
    -- sync-like code:
    local data = callbacker(api_crunch_data, then_create_report)

    print("4. creating report with data: " .. vim.inspect(data))
end)

-- RUN in nvim :=require("config.macros.screenpal.testco2")
--   part will finish before module imports, part after
