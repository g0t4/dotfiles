if not vim.fn.getcwd():match("%.config/hammerspoon$") then
    error("\n\n*** CURRENT DIRECTORY IS NOT INSIDE hammerspoon config, require calls in tests won't work...\n\n\tuse `cd $WES_DOTFILES/.config/hammerspoon && nvim`)\n\n")
end
require("config.tests.setup")
local histogram = require('devtools.diff.histogram')
local should = require('devtools.tests.should')
local combined = require('devtools.diff.combined')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')

require("config.macros.screenpal.co")
local TestTimer = require("config.macros.screenpal.co.tests.timer")
local Counter = require("config.macros.screenpal.co.tests.counter")

-- FYI alternative is to use async module, but I am happy with my run_async
-- local async = require('plenary.async.tests')

describe("TODO what was original purpose for this test???", function()
    -- TODO what did I mean by "bypasses creating coroutine?" ... was that it?
    --   IOTW review test categories and coverage of scenarios
    --   by the way I am happy with Counter and syncify categories below, so maybe move this into syncify if that's what it is covering
    --   AND/OR setup describe("sleep_ms") tests
    skip("test run_async + TestTimer works, bypasses creating coroutine", function()
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

local stop_after_this = only

describe("syncify", function()
    it("syncify returns multiple args unpacked", function()
        run_async(function()
            local result1, result2, result3 = syncify(function(cb)
                vim.schedule(function()
                    cb(3, 4, 5)
                end)
            end)
            assert.equal(3, result1)
            assert.equal(4, result2)
            assert.equal(5, result3)
        end)
    end)

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
        it("syncify completes and returns value", function()
            run_async(function()
                local counter = Counter:new()
                counter:increment()
                local result = syncify(function(cb)
                    vim.schedule(function()
                        counter:decrement()
                        cb(3)
                    end)
                    counter:wait(100)
                end)
                assert.equal(3, result)
            end)
        end)
        it("syncify twice completes and returns value", function()
            run_async(function()
                local counter = Counter:new()
                counter:increment()
                -- TODO test of hs.doAfter?
                local does_schedule = function(cb, what_result)
                    vim.schedule(function()
                        counter:decrement()
                        cb(what_result)
                    end)
                    counter:wait(100)
                end
                local result = syncify(does_schedule, 3)
                assert.equal(3, result)
                result = syncify(does_schedule, 13)
                assert.equal(13, result)
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
                            -- counter:decrement() -- this is the difference vs test above
                            cb()
                        end)
                        counter:wait(100)
                    end)
                end)
            end)
        end)
    end)
end)

---Simulate a current time value by passing a constant
---@param constant number Constant millisecond value to return.
local function make_get_ms_return(constant)
    local fn = TestTimer.throw_if_time_not_acceptable
    local info = debug.getinfo(fn, "u") -- populate lua_getinfo.nups (number up values)
    for i = 1, info.nups do
        local name = debug.getupvalue(fn, i)
        if name == "get_ms" then
            local function get_ms()
                return constant
            end
            debug.setupvalue(fn, i, get_ms)
            break
        end
    end
end

describe("TestTimer", function()
    -- PRN I could also rewrite this to use real delays and not rely on mocking time...
    --   I would've preferred that but what gptoss120b did here isn't terrible either
    local allowed_time_ms = 100
    local timer

    before_each(function()
        timer = TestTimer:new(allowed_time_ms)
        make_get_ms_return(1) -- reset get_ms to the real implementation after each test
    end)

    it("throws if over time", function()
        make_get_ms_return(timer.start_time + allowed_time_ms * 1.2) -- 20% over
        assert.has_error(function()
            timer:stop()
        end)
    end)

    it("throws if under time", function()
        make_get_ms_return(timer.start_time + allowed_time_ms * 0.7) -- 30% under
        assert.has_error(function()
            timer:stop()
        end)
    end)

    it("does not throw if at exact time", function()
        make_get_ms_return(timer.start_time + allowed_time_ms)
        assert.has_no.errors(function()
            timer:stop()
        end)
    end)

    it("does not throw if within tolerance of time", function()
        -- exactly at max bound (allowed + tolerance)
        make_get_ms_return(timer.start_time + allowed_time_ms + allowed_time_ms * 0.04)
        assert.has_no.errors(function()
            timer:stop()
        end)

        -- exactly at min bound (allowed - tolerance)
        make_get_ms_return(timer.start_time + allowed_time_ms - allowed_time_ms * 0.04)
        assert.has_no.errors(function()
            timer:stop()
        end)
    end)
end)
