local Counter = {}
Counter.__index = Counter

function Counter:new(expected)
    return setmetatable({ count = 0 }, self)
end

function Counter:increment() self.count = self.count + 1 end

function Counter:decrement() self.count = self.count - 1 end

function Counter:is_done() return self.count == 0 end

function Counter:wait(timeout)
    -- up to 1 second or timeout...
    -- this counter is intended for testing scenarios with near 0 delays, not timing tests
    --  use TestTimer for intentional delays
    local ok = vim.wait(timeout or 1000, function()
        -- print(self.count)
        return self:is_done()
    end, 10)
    assert(ok, ("Counter not done after %d ms (count=%d should be 0)")
        :format(timeout or 1000, self.count))
end

return Counter
