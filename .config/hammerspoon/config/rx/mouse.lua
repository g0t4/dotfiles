local rx = require 'rx'
local HammerspoonTimeoutScheduler = require("config.rx.hammerspoon_timeout_scheduler")

local M = {}

function M.mouseMovesObservable()
    local moves = rx.Subject.create()

    local mouseMoveWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
        -- print("location", location.x, location.y)
        -- we will always get current mouse position WHEN using it... that way it's never old in my case...
        --  really this is an alert "stream" that the mouse is moving, not a mouse event stream
        moves:onNext(true)
        return false -- Return false to allow the event to propagate
    end)

    local function stop()
        print("stopping mouseMovesObservable")
        mouseMoveWatcher:stop()
    end

    mouseMoveWatcher:start()

    return moves, stop
end

local function throttle(observable, delay_ms, scheduler)
    -- PRN use Observable.create (w/ nested Subscription.create)
    --   to handle multiple subscribers (so one call to throttled can be used repeatedly)
    --   and to handle unsub (so subscription to upstream observable can be cleaned up)
    --   though I dont care about these criteria currently

    local throttled = rx.Subject.create()
    local waiting = false
    local subscription = observable:subscribe(
        function(...)
            if waiting then
                -- ignore any events while throttled
                return
            end
            waiting = true
            -- TODO args ... ???
            throttled:onNext(...)
            scheduler:schedule(function()
                waiting = false
            end, delay_ms)
        end,

        -- just forward error/completed immediatley
        function(e) throttled:onError(e) end,
        function() throttled:onCompleted() end
    )
    return throttled
end

function M.mouseMovesThrottledObservable(delay_ms)
    -- FYI arguably I could be using: https://www.hammerspoon.org/docs/hs.timer.delayed.html for the narrow case of throttling

    delay_ms = delay_ms or 250

    --   luarocks install reactivex -- fork of rxlua, with some fixes for unsubscribe on take, IIUC -- also more recent release (2020)
    --      darn, this is constrianed to lua 5.3 max... why?
    --   luarocks install rxlua -- upstream (original repo) - last release 2017
    --      this is not limited to lua <5.3
    --   age of releases is not necessarily an issue beyond likley bug fixes... Rx is much like Ix (enumerable) in that the API is arguably stable and "commplete" if truly based on work done in RxJS (et al)

    local scheduler = HammerspoonTimeoutScheduler.create()
    local moves, stop_event_source = M.mouseMovesObservable()
    local throttled = throttle(moves, delay_ms, scheduler)

    local function stop()
        print("stopping mouseMovesThrottledObservable")
        -- this way, any pending timers are cancelled:
        scheduler:stop() -- immediately stop sending any more events
        stop_event_source() -- btw have to call after I stop the scheduler for some reason... otherwise onCompleted isn't passed along?
    end

    return throttled, stop
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
    local moves, stop_event_source = M.mouseMovesObservable()
    local debounced = moves:debounce(delay_ms, scheduler)

    local function stop()
        print("stopping mouseMovesDebouncedObservable")
        -- this way, any pending timers are cancelled:
        scheduler:stop() -- immediately stop sending any more events
        stop_event_source() -- btw have to call after I stop the scheduler for some reason... otherwise onCompleted isn't passed along?
    end

    return debounced, stop
end

return M
