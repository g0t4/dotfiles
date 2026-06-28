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
local Counter = require("config.macros.screenpal.co.tests.counter")

describe("Counter", function()
    -- TODO move to counter.tests.lua
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
