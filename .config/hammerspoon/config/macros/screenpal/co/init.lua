local log = require("config.logs").hammerspoons()
-- FYI! always check resume result for failure!!!
--   else wind up swallowing errors!

--- ensure we are running inside a non main coroutine
function run_async(what, ...)
    local running_thread, ismain = coroutine.running()
    log:info("ismain:", ismain, "|", "running_thread:", running_thread)
    -- DO not try to reuse main thread (coroutine), it is not yield/resumable
    if running_thread and not ismain then
        log:info("already have running, non-main coroutine, reusing its thread")
        what(...) -- equivalent of resume below
        return
    end

    log:info("creating coroutine (thread)...")
    local co = coroutine.create(what)
    -- ONLY call resume once, let `what` manage subsequent yield/resume (or delegate it to helpers like sleep_ms and callbacker)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        error("run_async: failed resuming coroutine:" .. tostring(err))
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
        -- log:info("sleep found vim")
        vim.defer_fn(callback, ms)
        coroutine.yield()
        return
    end

    local is_hs = hs ~= nil and hs.timer ~= nil and hs.timer.doAfter ~= nil
    if is_hs then
        -- useful in my hammerspoon "prod" config
        -- log:info("sleep found hs")
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

local function pick_scheduler()
    local host = require("devtools.host")

    if host.is_nvim() then
        return vim.schedule
    end

    if host.is_hammerspoon() then
        local function hs_sched(f)
            hs.timer.doAfter(0, f)
        end
        return hs_sched
    end

    local fail = "failed to detect nvim/hs... this shouldn't ever happen, indicates a bug in pick_scheduler"
    log:error(fail)
    error(fail)
end

local sched = pick_scheduler()

--- wrap a callback based method to appear synchronous using coroutines
-- PRN add type hints to syncify so it just works based on called method and its callback?
---@param call_this fun(fun(...), ...)  -- assumes callback is first arg then args are after
---@vararg any ...
---@return any ...
function syncify(call_this, ...)
    local co, is_main = coroutine.running()
    -- log:info("syncify - co: ", co, "is_main: ", is_main) -- debugging
    assert(co, "syncify: can only be called within a coroutine")
    assert(not is_main, "syncify: cannot be called in a main thread (coroutine)")
    -- cannot yield main thread... hence this won't work
    -- i suppose i could start a coroutine if is_main is true

    local captured_args = nil
    local resume_once_called = false
    local function resume_once()
        log:info("syncify resume_once, resumed:", resume_once_called)
        if resume_once_called then
            log:warn("syncify resume_once - SKIP b/c ALREADY RESUMED")
            return
        end
        resume_once_called = true

        -- schedule the resume, to avoid "cannot resume non-suspended coroutine"
        -- which happens during synchronous callback (b/c you are triggering resume before yield!! duh)
        sched(function()
            -- log:info("syncify before resume - coroutine_info:", coroutine_info(co))

            local status, err = coroutine.resume(co)
            log:info("syncify after resume - status: ", status, " err:", err)
            if not status then
                log:info("syncify unhandled exception in coroutine (after resume):\n\t", err, "\nstacktrace:", get_stack_trace())
                -- TODO why am I getting a second resume attempt? this is regardless if coroutine has unhandled exception
                -- - in fact if it has unhandled exception then this unhandled exception message is logged twice
                --   TODO why am I resuming a second time or is smth else doing that?
                --   FYI reproduce using "mute this" streamdewck button => sometimes timeout failure but that doesn't matter as no matter what I get this second resume failure
                --    "cannot resume dead coroutine stacktrace"
                -- [INFO ]  syncify unhandled exception in coroutine (after resume) cannot resume dead coroutine stacktrace: /Users/wesdemos/.hammerspoon/config/macros/screenpal/co.lua:161
                --
                -- OBSERVED: also getting this at start of mute this...
                --   [INFO ]  WARNING - callback invoked resume before yielded, allowing resume
                --
                --  ok run_async is nested in the case where I have the double resume...
                --   and run_async explicitly calls coroutine.resume() too...
                --   commenting it out in nested case fixes double resume error!
            end
        end)
    end

    local function after_call_this(...)
        captured_args = { ... }
        log:info("syncify call_this captured_args", captured_args)
        -- FYI captured_args are returned below (seemingly synchronously b/c this coroutine waits for them to be ready before returning)
        resume_once()
    end

    call_this(after_call_this, ...)

    -- as long as you are `sched`uling during a sync callback ("making it async", IOTW resume is not called synchronously)
    -- then there's no way to resume before yielding!
    coroutine.yield()

    local _unpack = unpack or table.unpack
    log:info("syncify captured_args:", _unpack)
    return _unpack(captured_args)
end
