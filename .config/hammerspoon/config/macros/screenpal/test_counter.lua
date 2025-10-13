local Counter = {}
Counter.__index = Counter

function Counter:new(expected)
    return setmetatable({ count = 0 }, self)
end

function Counter:increment() self.count = self.count + 1 end

function Counter:decrement() self.count = self.count - 1 end

function Counter:done()
    if self.count == 0 then
        return
    end
    error("FAILURE COUNT SHOULD BE ZERO - counter:done() - count: " .. self.count)
end

function Counter:wait(timeout)
    -- up to 1 second or timeout...
    -- this counter is intended for testing scenarios with near 0 delays, not timing tests
    --  use TestTimer for intentional delays
    vim.wait(timeout or 1000, function() self:done() end, 10)
end

return Counter
