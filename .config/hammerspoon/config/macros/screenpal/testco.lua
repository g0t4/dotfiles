describe("test", function()
    -- it("test coroutine", function()
    --     function crunch_data(callback)
    --         print("start crunch data")
    --         vim.defer_fn(function()
    --             print("end crunch data")
    --             callback()
    --             print("callback called")
    --         end, 100)
    --     end
    --
    --     local co = coroutine.running()
    --     print("co initial status", coroutine.status(co))
    --
    --     function build_report()
    --         function then_create_report()
    --             print("creating report")
    --             coroutine.resume(co)
    --         end
    --
    --         print("start building report.... before crunch_data called")
    --         crunch_data(then_create_report)
    --     end
    --
    --     -- coroutine.resume(co)
    --     -- print("co2 status", coroutine.status(co))
    --     build_report()
    --     coroutine.yield()
    --     -- resume must be called (on co, the current/running coroutine) before we get here
    -- end)


    -- it("co-routines", function()
    --     local co_thread1 = coroutine.running()
    --     function price_feed()
    --         -- resume1
    --         coroutine.yield(10)
    --         -- resume2
    --         coroutine.yield(11)
    --         -- resume3
    --         coroutine.yield(16)
    --         -- resume4
    --         print("thread2's price_feed is gonna resume thread1")
    --         coroutine.resume(co_thread1)
    --     end
    --
    --     -- local co = coroutine.running()
    --     local co_thread2 = coroutine.create(price_feed)
    --     print("co status (after create):", coroutine.status(co_thread2))
    --     vim.defer_fn(function()
    --         print("TIME IS OUT")
    --         coroutine.resume(co_thread1)
    --     end, 1000)
    --     local _, price = coroutine.resume(co_thread2)
    --     print("price1", price, "co_thread2 status:", coroutine.status(co_thread2))
    --     local _, price = coroutine.resume(co_thread2)
    --     print("price2", price, "co_thread2 status:", coroutine.status(co_thread2))
    --     local _, price = coroutine.resume(co_thread2)
    --     print("price3", price, "co_thread2 status:", coroutine.status(co_thread2))
    --     vim.schedule(function()
    --         -- print("scedule resuming thread1")
    --         -- coroutine.resume(co_thread1)
    --         print("scedule resuming thread2")
    --         coroutine.resume(co_thread2)
    --     end)
    --     coroutine.yield() -- test_co
    -- end)

    function callbacker(call_this, ...)
        --- cooperative sleeper (non-blocking)
        local co, is_main = coroutine.running()

        local captured_args = nil -- TODO only need this for a callbacker equivalent
        call_this(function(...)
            captured_args = ...
            coroutine.resume(co)
        end, ...)

        coroutine.yield()
        print("    3. callbacker captured args:", vim.inspect(captured_args))
        return captured_args
    end

    function sleeper2(ms)
        callbacker(vim.defer_fn, ms)
    end

    function sleeper(ms)
        --- cooperative sleeper (non-blocking)
        local co, is_main = coroutine.running()
        -- TODO create if not exist? or if is main?
        vim.defer_fn(function()
            coroutine.resume(co)
        end, ms)
        coroutine.yield()
        print("    3. sleeper done")
    end

    it("figure out sleeper, callbacker and sleeper+callbacker==sleeper2", function()
        local test_co = coroutine.running()
        function test_code()
            print("  2. before sleeper")
            sleeper2(500)
            print("  4. after sleeper")
            coroutine.resume(test_co)
        end

        print("1. before test_code()")
        test_code()
        print("5. after test_code()")
    end)

    function api_crunch_data(callback)
        print("2. start crunch data")
        vim.defer_fn(function()
            print("3. end crunch data")
            callback({ 1, 5, 10 })
            print("?. after callback - test finishes before this b/c callback resumes and finishes it... this may keep running if test runner doesn't stop first")
        end, 100)
    end

    it("crunch_data with callback", function()
        local test_co = coroutine.running()

        function build_report()
            function then_create_report(data)
                print("4. creating report with data: " .. vim.inspect(data))
                coroutine.resume(test_co) -- triggers test to complete
            end

            print("1. start building report.... before crunch_data called")
            api_crunch_data(then_create_report)
        end

        build_report()
        coroutine.yield() -- yield test_co
        print("5. test done")
    end)

    it("TODO crunch_data with callbacker", function()
        -- TREAT AS BLACKBOX, just takes callback and you wanna call it w/o callbacker in a sync looking style

        local test_co = coroutine.running()

        function build_report()
            print("1. start building report.... before crunch_data called")
            local data = callbacker(api_crunch_data, then_create_report)

            print("4. creating report with data: " .. vim.inspect(data))
            coroutine.resume(test_co) -- triggers test to complete
        end

        build_report()
        coroutine.yield() -- yield test_co
        print("5. test done")
    end)
end)
