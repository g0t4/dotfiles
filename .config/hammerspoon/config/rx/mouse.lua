local rx = require 'rx'
local HammerspoonTimeoutScheduler = require("config.rx.hammerspoon_timeout_scheduler")

local M = {}

function M.mouseMovesObservable()
    local moves = rx.Subject.create()

    local mouseMoveWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(event)
        -- print("location", location.x, location.y)
        -- we will always get current mouse position WHEN using it... that way it's never old in my case...
        --  really this is an alert "stream" that the mouse is moving, not a mouse event stream
        moves:onNext(true)
        return false -- Return false to allow the event to propagate
    end)

    local function stop()
        print("stopping mouseMovesObservable")
        mouseMoveWatcher:stop()
        -- this way, any pending timers are cancelled:
        moves:onCompleted() -- send completed event
        -- TODO shouldn't this use unsubscribe to stop the timer at least? and maybe also the event source if I make that interface return a Subscription too
    end

    mouseMoveWatcher:start()

    return moves, stop
end

function M.mouseMovesDebouncedObservable(delay_ms)
    -- FYI arguably I could be using: https://www.hammerspoon.org/docs/hs.timer.delayed.html for the narrow case of debouncing

    delay_ms = delay_ms or 250

    --   luarocks install reactivex -- fork of rxlua, with some fixes for unsubscribe on take, IIUC -- also more recent release (2020)
    --      darn, this is constrianed to lua 5.3 max... why?
    --   luarocks install rxlua -- upstream (original repo) - last release 2017
    --      this is not limited to lua <5.3
    --   age of releases is not necessarily an issue beyond likley bug fixes... Rx is much like Ix (enumerable) in that the API is arguably stable and "commplete" if truly based on work done in RxJS (et al)

    local scheduler = HammerspoonTimeoutScheduler.create()
    local moves = rx.Subject.create()

    local mouseMoveWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(event)
        local mousePos = hs.mouse.absolutePosition()
        moves:onNext(mousePos)
        return false -- Return false to allow the event to propagate
    end)

    local debounced = moves:debounce(delay_ms, scheduler)

    local function stop()
        print("stopping mouseMovesDebouncedObservable")
        mouseMoveWatcher:stop()
        -- this way, any pending timers are cancelled:
        scheduler:stop()
        moves:onCompleted() -- send completed event
        -- TODO shouldn't this use unsubscribe to stop the timer at least? and maybe also the event source if I make that interface return a Subscription too
    end

    mouseMoveWatcher:start()

    return debounced, stop
end

return M
