local log = require("config.logs").hammerspoons()
local host = require("devtools.host")

---@class Timer
---@field _overall_start number
---@field _last_start number
---@field _logs {message:string, duration:number}[]
local Timer = {}
Timer.__index = Timer

local function get_now_in_nanoseconds_counter()
    if host.is_hammerspoon() then
        -- hs.timer.absoluteTime() returns nanoseconds
        return hs.timer.absoluteTime() / 1e9
    else
        local uv = vim.uv or vim.loop
        return uv.hrtime() / 1e9
    end
end

---Creates a new Timer instance.
---@return Timer
function Timer.new()
    local now = get_now_in_nanoseconds_counter()
    local obj = {
        _overall_start = now,
        _last_start = now,
        _logs = {},
    }
    setmetatable(obj, Timer)
    return obj
end

---@param message string
function Timer:capture(message)
    local now = get_now_in_nanoseconds_counter()
    local duration = now - self._last_start
    self._last_start = now
    table.insert(self._logs, { message = message, duration = duration })
end

---@param elapsed_seconds number
---@return string
function format_elapsed_time(elapsed_seconds)
    if elapsed_seconds >= 1 then
        return string.format("** %.3f s **", elapsed_seconds)
    end
    local ms = elapsed_seconds * 1e3
    if ms >= 1 then
        local time = string.format("%.2f ms", ms)
        if ms > 10 then
            return "* " .. time .. " *"
        end
        return time
    end
    local us = elapsed_seconds * 1e6
    if us >= 1 then
        return string.format("%.0f µs", us)
    end
    local ns = elapsed_seconds * 1e9
    return string.format("%d ns", math.floor(ns + 0.5))
end

function Timer:log_timing()
    local overall = format_elapsed_time(get_now_in_nanoseconds_counter() - self._overall_start)
    log:info(string.format("Overall time: %s", overall))
    for _, entry in ipairs(self._logs) do
        log:info(string.format("  %s: %s", entry.message, format_elapsed_time(entry.duration)))
    end
end

function Timer.time_this(fn, description)
    local timer = Timer.new()
    local result = fn()
    timer:log_timing()
    return result
end

return Timer
