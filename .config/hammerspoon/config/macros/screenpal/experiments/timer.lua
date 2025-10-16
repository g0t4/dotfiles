---@class Timer
---@field _overall_start number
---@field _last_start number
---@field _logs {message:string, duration:number}[]
local Timer = {}
Timer.__index = Timer

local function get_time()
    return hs.timer.secondsSinceEpoch()
end

---Creates a new Timer instance.
---@return Timer
function Timer.new()
    local now = get_time()
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
    local now = get_time()
    local duration = now - self._last_start
    self._last_start = now
    table.insert(self._logs, { message = message, duration = duration })
end

function Timer:print_timing()
    local total_us = (get_time() - self._overall_start) * 1e6
    print(string.format("Overall: %.0f µs", total_us))
    for _, entry in ipairs(self._logs) do
        local dur_us = entry.duration * 1e6
        print(string.format("  %s: %.0f µs", entry.message, dur_us))
    end
end

return Timer
