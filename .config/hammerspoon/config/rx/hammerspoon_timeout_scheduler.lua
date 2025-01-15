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

--- Schedules an action to run at a future point in time.
-- @arg {function} action
-- @arg {number=0} delay, in milliseconds.
-- @returns {rx.Subscription}
function HammerspoonTimeoutScheduler:schedule(action, delay, ...)
    local packed_args = { ... }
    -- LUV timer example:
    --   https://github.com/luvit/luv/blob/master/examples/timers.lua

    -- FYI https://www.hammerspoon.org/docs/hs.timer.html#doAfter
    self.timer = hs.timer.doAfter(delay / 1000, function()
        action(table.unpack(packed_args))
    end)

    return rx.Subscription.create(function()
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
