local log = require("config.logs").hammerspoons()
local Timer = require("devtools.logs.timer")
local CoroutineStateTracker = require("devtools.co.state")

-- FYI! always check resume result for failure!!!
--   else wind up swallowing errors!

--- ensure we are running inside a non main coroutine
function ensure_in_coroutine(what, ...)
    local running_thread, ismain = coroutine.running()
    -- log:info("ismain:", ismain, "|", "running_thread:", running_thread)
    -- DO not try to reuse main thread (coroutine), it is not yield/resumable
    if running_thread and not ismain then
        -- log:info("already have running, non-main coroutine, reusing it")

        local timer = Timer.new()
        CoroutineStateTracker.set("timer", timer)
        what(...)
        return
    end

    -- log:info("creating coroutine (thread)...")
    local co = coroutine.create(what)
    -- ONLY call resume once, let `what` manage subsequent yield/resume (or delegate it to helpers like sleep_ms and callbacker)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        local failure = "ensure_in_coroutine: failed resuming coroutine "
        log:error(failure, err)
        error(failure .. tostring(err))
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
    local need_to_yield = true
    local function resume_once()
        if resume_once_called then
            log:warn("syncify resume_once called 2+ times, that shouldn't happen, ignoring this call...")
            return
        end
        resume_once_called = true

        sched(function()
            -- FYI if call_this has something like vim.wait that pumps event loop then you can wind up here before coroutine.yield() is called
            --   that is outside of what I intended to support in syncify (mostly a callback => sync tool... CST)... no plans to support vim.wait in the call_this
            --   that said, instead of letting things explode, check assumption that it is ok to resume here
            local status = coroutine.status(co)
            -- log:info("coroutine status before resume:", status)
            if status ~= "suspended" then
                -- log:info("coroutine is not yet suspended")
                -- NBD now as we handle that gracefully!
                -- just means this code ran before yield below, so tell yield to skip and then we can skip resume here!
                need_to_yield = false
                return
            end
            local status, err = coroutine.resume(co)
            if not status then
                log:error("syncify unhandled exception in coroutine (after resume):\n\t", err, "\nstacktrace:", get_stack_trace())
            end
        end)
    end

    local function after_call_this(...)
        captured_args = { ... }
        -- FYI captured_args are returned below (seemingly synchronously b/c this coroutine waits (yields) for them to be ready before returning)
        resume_once()
    end

    call_this(after_call_this, ...)

    if need_to_yield then
        coroutine.yield()
    end

    local _unpack = unpack or table.unpack
    return _unpack(captured_args)
end
