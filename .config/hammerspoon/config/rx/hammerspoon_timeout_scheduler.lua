local rx = require 'rx'
local HammerspoonTimeoutScheduler = {}
HammerspoonTimeoutScheduler.__index = HammerspoonTimeoutScheduler
HammerspoonTimeoutScheduler.__tostring = 'TimeoutScheduler'

-- FYI the rxlua TimeoutScheduler is based on an outdated version of `luv`
-- and I need it to use hammerspoon's event loop...
-- THUS, wrap hs.timer.doAfter to make a new TimeoutScheduler

function HammerspoonTimeoutScheduler.create()
    return setmetatable({}, HammerspoonTimeoutScheduler)
end

--- Schedules action to run after delay
---@param action function
---@param delay number @in milliseconds
---@return Subscription
function HammerspoonTimeoutScheduler:schedule(action, delay, ...)
    local packed_args = { ... }
    -- LUV timer example:
    --   https://github.com/luvit/luv/blob/master/examples/timers.lua

    -- FYI https://www.hammerspoon.org/docs/hs.timer.html#doAfter
    self.timer = hs.timer.doAfter(delay / 1000, function()
        action(table.unpack(packed_args))
    end)

    return rx.Subscription.create(function()
        -- FYI I am not relying on unsubscribe to stop upstream event source, it can stop this scheduler, that's fine
        --    but I am also gonna stop event source cuz I don't want to keep firing after stopping (one at a time sub is intended, but yeah wouldn't want it to run for days at a time after stopping it)
        -- unsubscribe function (when observer unsubscribes)
        self.timer:stop()
    end)
end

function HammerspoonTimeoutScheduler:stop()
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
end

return HammerspoonTimeoutScheduler
