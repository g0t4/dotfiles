-- require("config.macros.screenpal")
require("config.macros.screenpal.helpers_tested")

-- using busted for testing
--   luarocks install busted
-- TODO can I get this to work from plenary's file runner in neovim, I like that UX (not necessary but might be nice)...
--   issue would be package.path (notably hs deps)
--   also static refs to hs apis hs.timer...

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
