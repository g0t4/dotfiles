require("config.hs_harness.busted") -- PRN assume loaded by hs init?

describe("FOO", function()
    it("dammit", function()
        local log = require("config.logs").hammerspoons()
        log:info("TESTING WORKS")
        assert.same("bar", true)
    end)
end)

-- failure to STDOUT => float window in nvim for <leader>hs
-- assert.same("fuuu", true)
