-- FYI this doesn't need to be everywhere, just put it in some prominent tests as a reminder really...
if not vim.fn.getcwd():match("%.config/hammerspoon$") then
    error("\n\n*** CURRENT DIRECTORY IS NOT INSIDE hammerspoon config: (run nvim from this dir to use pleanry tests:  .config/hammerspoon)\n")
end
require("config.macros.screenpal.co")
local TestTimer = require("config.macros.screenpal.test_timing")
local Counter = require("config.macros.screenpal.test_counter")

-- FYI alternative is to use async module, but I am happy with my run_async
-- local async = require('plenary.async.tests')

describe("coroutine helper tests", function()
    -- TODO! add TestTimer tests? explicit examples to make sure I don't have bugs in it?
    --   TODO validate throws if over time
    --   TODO validate throws if under time
    --   TODO ensure does not throw if within time
    --   TODO ensure does not throw if within tolerance of time

    it("test run_async + TestTimer works, bypasses creating coroutine", function()
        -- !!! MUST wrap with run_async for _busted_ test runner to work
        -- - b/c busted (standalone cmd) runs tests in main thread! and thus the yield in sleep_ms blows up on the main thread (cannot yield/resume the main coroutine/thread)
        -- BTW plenary's runner (in nvim) does not run tests in main coroutine... so it will work w/o run_async (but leave this here to be compat with busted)
        run_async(function()
            local timer = TestTimer:new(250)
            sleep_ms(250)
            timer:stop()
        end)
    end)

    it("integration test - validate Counter works with immediate/sync callback inside run_async too", function()
        -- FYI run_async is not needed in this test
        --   but keep it to mirror other tests
        --   to trigger a failure here on an easy to fix test
        run_async(function()
            local counter = Counter:new()
            counter:increment()
            counter:decrement()
            counter:done()
        end)
    end)
end)
