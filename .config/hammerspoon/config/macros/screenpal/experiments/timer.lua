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

---Prints all captured timings and the total elapsed time.
function Timer:print_timing()
    local total = get_time() - self._overall_start
    print(string.format("Overall: %.6f seconds", total))
    for _, entry in ipairs(self._logs) do
        print(string.format("  %s: %.6f seconds", entry.message, entry.duration))
    end
end

return Timer
