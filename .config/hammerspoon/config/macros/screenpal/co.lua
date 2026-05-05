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

---@param co thread
---@return string
local function coroutine_info(co)
    local id = tostring(co) -- thread: 0x15209 (memory addy) ... do  not hs.inspect else you will lose memory addy part

    -- Status of the coroutine (running, suspended, dead, etc.)
    local status = coroutine.status(co)

    -- Debug info about where the coroutine's function was defined
    local level = 2
    local dbg = debug.getinfo(co, level, "S") -- 2 is caller of coroutine_info func ( 1 == coroutine_info itself, 0 == debug.getinfo)
    local source = dbg and dbg.source or "unknown"
    local line = dbg and dbg.linedefined or -1

    return string.format(
        "%s – status: %s – defined at %s:%d",
        id, status, source, line
    )
end

---@param start_level integer|nil starting stack level (defaults to 1, the caller of this function)
---@return string stack_trace multiline stack trace
function get_stack_trace(start_level)
    start_level = start_level or 2

    ---@type string[]
    local stack_trace_lines = {}
    local level = start_level
    while true do
        local info = debug.getinfo(level, "Sl")
        if not info then
            break
        end
        table.insert(
            stack_trace_lines,
            string.format("%s:%d", info.short_src, info.currentline)
        )
        level = level + 1
    end

    return table.concat(stack_trace_lines, "\n")
end

--- wrap a callback based method to appear synchronous using coroutines
-- PRN add type hints to syncify so it just works based on called method and its callback?
---@param call_this fun(fun(...), ...)  -- assumes callback is first arg then args are after
---@vararg any ...
---@return any ...
function syncify(call_this, ...)
    local co, is_main = coroutine.running()
    print("syncify - co: ", co, "is_main: ", is_main) -- debugging
    assert(co, "syncify: can only be called within a coroutine")
    assert(not is_main, "syncify: cannot be called in a main thread (coroutine)")
    -- cannot yield main thread... hence this won't work
    -- i suppose i could start a coroutine if is_main is true

    local captured_args = nil
    local resumed = false
    local yielded = false
    local function resume_once()
        print("syncify resume_once, resumed:", resumed)
        if resumed then
            print("syncify resume_once - SKIP b/c ALREADY RESUMED")
            return
        end
        if not yielded then
            print("WARNING - callback invoked resume before yielded, allowing resume")
            -- do not stop the resume, just note it to look into
        end
        resumed = true

        -- schedule the resume, to avoid "cannot resume non-suspended coroutine"
        -- which happens if call_this calls this callback synchronously
        -- TODO I do not like fallback code like this:
        local sched = _G.vim and vim.schedule
            or (hs and function(f)
                print("syncify resume_once hs.doAfter")
                hs.timer.doAfter(0, f)
            end)
            or function(f)
                -- TODO why not throw? isn't this an issue?
                print("syncify resume_once IMMEDIATE... no vim/hs defer options in place")
                f()
            end

        sched(function()
            print("syncify resume_once scheduled - coroutine_info:", coroutine_info(co))

            local status, err = coroutine.resume(co)
            print("syncify resume_once scheduled - status: ", vim.inspect(status), " err:", vim.inspect(err))
            if not status then
                print("syncify resume_once scheduled: RESUME FAILED", err, "stacktrace:", get_stack_trace())
            end
        end)
    end

    call_this(function(...)
        captured_args = { ... }
        print("syncify call_this captured_args", vim.inspect(captured_args))
        resume_once()
    end, ...)

    yielded = true
    if not resumed then
        -- don't call yield if resume already triggered, no point
        --  again this would have to be due to synchronous callback
        coroutine.yield()
    end

    local _unpack = unpack or table.unpack
    print("syncify captured_args:", vim.inspect(_unpack))
    return _unpack(captured_args)
end
