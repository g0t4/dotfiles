if not vim.fn.getcwd():match("%.config/hammerspoon$") then
    error("\n\n*** CURRENT DIRECTORY IS NOT INSIDE hammerspoon config, require calls in tests won't work...\n\n\tuse `cd $WES_DOTFILES/.config/hammerspoon && nvim`)\n\n")
end
require("config.tests.setup")
local should = require('devtools.tests.should')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')
local log = require("config.logs").hammerspoons()

local underscore = require("config.helpers.underscore")

describe("underscore - tableUnion", function()
    it("merges without duplicates", function()
        local result = underscore.union({ 1, 2, 3 }, { 3, 4, 5 })
        assert.are.same({ 1, 2, 3, 4, 5 }, result)
    end)
    -- TODO add more test as cases arise
end)
