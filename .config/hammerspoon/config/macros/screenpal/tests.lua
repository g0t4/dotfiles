require('config.tests.setup')
require('config.macros.screenpal') -- TODO test more of the logic in here
-- require('config.macros.screenpal.helpers') -- FYI testing this is already imported via screenpal/init.lua
require("config.macros.screenpal.co")

-- !!! see run_unit_tests.fish for more about testing

describe("cos", function()
    it("test w/o run_async because test already has a coroutine", function()
        print("before sleep")
        sleep_ms(250)
        print("after sleep")
    end)

    it("test run_async works too, bypasses creating coroutine", function()
        run_async(function()
            print("before sleep")
            sleep_ms(250)
            print("after sleep")
        end)
    end)
end)

describe("parse_time_to_seconds", function()
    it("should parse seconds only", function()
        assert.equal(42, parse_time_to_seconds("42"))
    end)

    it("should parse minutes:seconds", function()
        assert.equal(155, parse_time_to_seconds("2:35"))
    end)

    it("should parse hours:minutes:seconds", function()
        assert.equal(3723, parse_time_to_seconds("1:2:3"))
    end)

    it("should handle decimal seconds", function()
        assert.equal(155.28, parse_time_to_seconds("2:35.28"))
    end)

    it("should handle zero values", function()
        assert.equal(0, parse_time_to_seconds("0"))
        assert.equal(0, parse_time_to_seconds("0:0"))
        assert.equal(0, parse_time_to_seconds("0:0:0"))
    end)

    it("should handle single digit components", function()
        assert.equal(3661, parse_time_to_seconds("1:1:1"))
    end)

    it("should throw error for invalid time format with more than 3 components", function()
        assert.has_error(function()
            parse_time_to_seconds("1:2:3:4")
        end, "Cannot have time component bigger than hours  (h:m:s): 1:2:3:4")
    end)
end)
