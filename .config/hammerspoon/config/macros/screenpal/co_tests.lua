require("config.macros.screenpal.co")

function get_ms()
    return vim.uv.hrtime() / 1e6
end

describe("cos", function()
    it("test w/o run_async because test already has a coroutine", function()
        local _start = get_ms()
        sleep_ms(250)
        local _end = get_ms()
        local actual_ms = _end - _start
        if actual_ms < 240 then
            error("sleep was not long enough: " .. actual_ms .. " ms")
        end
        if actual_ms > 260 then
            error("sleep was too long: " .. actual_ms .. " ms")
        end
    end)

    it("test run_async works too, bypasses creating coroutine", function()
        run_async(function()
            print("before sleep")
            sleep_ms(250)
            print("after sleep")
        end)
    end)
end)
