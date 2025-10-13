-- FYI this doesn't need to be everywhere, just put it in some prominent tests as a reminder really...
if not vim.fn.getcwd():match("%.config/hammerspoon$") then
    error("\n\n*** CURRENT DIRECTORY IS NOT INSIDE hammerspoon config: (run nvim from this dir to use pleanry tests:  .config/hammerspoon)\n")
end
require("config.macros.screenpal.co")
local TestTimer = require("config.macros.screenpal.test_timing")

describe("coroutine helper tests", function()
    it("test run_async works too, bypasses creating coroutine", function()
        -- MUST wrap with run_async for _busted_ test runner to work
        -- - b/c busted runs tests in main thread! and thus the yield in sleep_ms blows up on the main thread (cannot yield/resume the main coroutine/thread)
        -- BTW plenary's runner does not run tests in main coroutine... so it will work w/o run_async (but leave this here to be compat with busted)
        run_async(function()
            local timer = TestTimer:new(250)
            sleep_ms(250)
            timer:stop()
        end)
    end)
end)
