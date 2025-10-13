-- FYI this doesn't need to be everywhere, just put it in some prominent tests as a reminder really...
if not vim.fn.getcwd():match("%.config/hammerspoon$") then
    error("\n\n*** CURRENT DIRECTORY IS NOT INSIDE hammerspoon config: (run nvim from this dir to use pleanry tests:  .config/hammerspoon)\n")
end
require("config.macros.screenpal.co")
local TestTimer = require("config.macros.screenpal.test_timing")
local Counter = require("config.macros.screenpal.test_counter")

-- FYI alternative is to use async module, but I am happy with my run_async
-- local async = require('plenary.async.tests')

describe("TODO what was original purpose for this test???", function()
    -- TODO what did I mean by "bypasses creating coroutine?" ... was that it?
    --   IOTW review test categories and coverage of scenarios
    --   by the way I am happy with Counter and syncify categories below, so maybe move this into syncify if that's what it is covering
    --   AND/OR setup describe("sleep_ms") tests
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
end)

describe("Counter", function()
    it("wait does not throw if count is zero before timeout", function()
        local counter = Counter:new()
        counter:increment()
        counter:decrement()
        -- make it fast, timeout duration is unimportant here
        counter:wait(10)
    end)

    it("wait throws after timeout, if count is not zero", function()
        assert.has_error(function()
            local counter = Counter:new()
            counter:increment()
            -- make it fast, timeout duration is unimportant here
            counter:wait(10)
        end, "Counter not done after 10 ms (count=1 should be 0)")
    end)
end)

describe("syncify", function()
    -- FYI! syncify scenarios are not fully covered
    it("sync, immediate callbacks work", function()
        -- YES!!! we have the warning here! this is what I wanted to reproduce!
        --   WARNING - callback invoked resume before yielded, allowing resume
        run_async(function()
            local counter = Counter:new()
            counter:increment()
            syncify(function(cb)
                counter:decrement()
                cb()
            end)
            counter:wait()
        end)
    end)


    describe("works with vim.defer_fn", function()
        it("counter ok", function()
            run_async(function()
                local counter = Counter:new()
                counter:increment()
                syncify(function(cb)
                    vim.schedule(function()
                        counter:decrement()
                        cb()
                    end)
                    counter:wait(100)
                end)
            end)
        end)
        it("counter timeout", function()
            -- TODO do I want this test too?
            --  my inclination was to add it to make sure it fails too
            --  but it does overlap with other Counter timeout above so long term maybe nuke if not needed
            --  TODO review syncify/run_async and make sure you understand if this test is needed, keep it for now
            assert.has_error(function()
                run_async(function()
                    local counter = Counter:new()
                    counter:increment()
                    syncify(function(cb)
                        vim.schedule(function()
                            -- counter:decrement()
                            cb()
                        end)
                        counter:wait(100)
                    end)
                end)
            end)
        end)
    end)
end)

-- TODO add tests for TestTimer helper?
--   TODO validate throws if over time
--   TODO validate throws if under time
--   TODO ensure does not throw if within time
--   TODO ensure does not throw if within tolerance of time
