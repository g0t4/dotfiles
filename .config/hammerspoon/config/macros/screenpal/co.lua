-- FYI! always check resume result for failure!!!
--   else wind up swallowing errors!

function run_async(what, ...)
    local running, ismain = coroutine.running()
    -- print("running:", running)
    -- print("ismain:", ismain)
    -- DO not try to reuse main thread (coroutine), it is not yield/resumable
    if running and not ismain then
        -- print("already have running, non-main coroutine, reusing its thread")
        what(...) -- equivalent of resume below
        return
    end

    -- ONLY call resume once, let what then manage yield/resume on its own (or delegate it to helpers like sleep_ms and callbacker below)
    local co = coroutine.create(what)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        error("Failed resuming coroutine:" .. tostring(err))
    end
end

function sleep_ms(ms)
    local co = coroutine.running()
    assert(co, "sleep can only be called within a coroutine")

    function callback()
        coroutine.resume(co)
    end

    if vim ~= nil and vim.defer_fn ~= nil then
        -- useful in nvim lua code
        -- ALSO useful for plenary test runs
        -- print("sleep found vim")
        vim.defer_fn(callback, ms)
        coroutine.yield()
        return
    end

    local is_hs = hs ~= nil and hs.timer ~= nil and hs.timer.doAfter ~= nil
    if is_hs then
        -- useful in my hammerspoon "prod" config
        -- print("sleep found hs")
        seconds = ms / 1000
        hs.timer.doAfter(seconds, callback)
        coroutine.yield()
        return
    end

    local luv = require("luv")
    if luv then
        luv.new_timer():start(ms, 0, callback)
        coroutine.yield()
        return
    end

    error("NOT SUPPORTED TEST ENV... USE _PLENARY_")
end

---PRN could have callbacker_lastarg(...,fun(...)) that takes callback as last arg
---@param call_this fun(fun(...), ...)  -- assumes callback is first arg then args are after
---@vararg any ...
---@return any ...
function callbacker(call_this, ...)
    local co, is_main = coroutine.running()
    assert(co, "callbacker can only be called within a coroutine")
    assert(not is_main, "callbacker cannot be called in a main thread (coroutine)")
    -- cannot yield main thread... hence this won't work
    -- i suppose i could start a coroutine if is_main is true

    local captured_args = nil
    local resumed = false
    local function resume_once()
        if resumed then return end
        resumed = true

        -- schedule the resume, to avoid "cannot resume non-suspended coroutine"
        -- which happens if call_this calls this callback synchronously
        local sched = _G.vim and vim.schedule
            or (hs and function(f) hs.timer.doAfter(0, f) end)
            or function(f) f() end
        sched(function()
            local status, err = coroutine.resume(co)
            if not status then
                print("callbacker - resume failed", err)
            end
        end)
    end

    call_this(function(...)
        captured_args = { ... }
        resume_once()
    end, ...)

    coroutine.yield()
    -- print("cap2", captured_args)
    if unpack then
        return unpack(captured_args)
    end
    return table.unpack(captured_args)
end
