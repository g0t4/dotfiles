local rx = require 'rx'
local HammerspoonTimeoutScheduler = require("config.rx.hammerspoon_timeout_scheduler")

local M = {}

function M.mouseMovesObservable(delay_ms)
    delay_ms = delay_ms or 250
    --   TODO debounce events (so UI is responsive and don't query element info until stopped moving)
    --   ideally don't respond to the input until it stops for x ms
    --
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
        print("stopping mouseMovesObservable")
        mouseMoveWatcher:stop()
        -- this way, any pending timers are cancelled:
        scheduler:stop()
    end

    mouseMoveWatcher:start()

    return debounced, stop

    -- example of pushing values (b/c its a subject, too):
    -- moves:onNext({ x = 0, y = 0 })
    -- moves:onCompleted()
    -- moves:onError("fuuuuu") -- never received b/c commplete already called
end

return M
