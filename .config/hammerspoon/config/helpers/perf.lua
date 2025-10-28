-- PRN setup a timing module? and pass a block of code to be timed?
function get_time()
    return hs.timer.secondsSinceEpoch()
end

function get_elapsed_time_since(start_time)
    return get_time() - start_time
end

local function log_if_slower_than_x_ms(minimum_ms, message, start_time)
    local elapsed_time_ms = get_elapsed_time_in_milliseconds(start_time)

    if elapsed_time_ms > minimum_ms then
        print("WARN " .. elapsed_time_ms .. " ms - " .. message)
    end

    return elapsed_time_ms
end

function log_if_slower_than_100ms(message, start_time)
    log_if_slower_than_x_ms(100, message, start_time)
end

function get_elapsed_time_in_milliseconds(start_time)
    local elapsed_time_seconds = get_elapsed_time_since(start_time)
    -- round to 1 decimal place
    return math.floor(elapsed_time_seconds * 10000 + 0.5) / 10
end

function get_elapsed_time_in_nanoseconds(start_time)
    local elapsed_time_seconds = get_elapsed_time_since(start_time)
    return math.floor(elapsed_time_seconds * 1000000000)
end

function print_took(message, start_time)
    local elapsed_time_milliseconds = get_elapsed_time_in_milliseconds(start_time)
    print(message .. " took " .. elapsed_time_milliseconds .. " ms")
end

function print_took_in_nanoseconds(message, start_time)
    local elapsed_time_nanoseconds = get_elapsed_time_in_nanoseconds(start_time)
    print(message .. " took " .. elapsed_time_nanoseconds .. " ns")
end

function print_took_in_microseconds(message, start_time)
    local elapsed_time_microseconds = get_elapsed_time_in_nanoseconds(start_time) / 1000
    print(message .. " took " .. elapsed_time_microseconds .. " us")
end

function start_profiler()
    local ProFi = require("ProFi")
    ProFi:start()
end

function stop_profiler(path)
    print("stop_profiler", path)
    path = path or "profi.txt"
    local ProFi = require("ProFi")
    ProFi:stop()
    ProFi:writeReport(path)
end
