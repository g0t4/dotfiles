-- testing:
require("non-plugins.code_notes.setup").modify_package_path()
local assert = require("luassert")
local buffers = require("devtools.tests.buffers")
-- system under test:
local M = require("non-plugins.code_notes")

describe("slice", function()
    local bufnr

    before_each(function()
        bufnr = buffers.new_buffer_with_lines({
            -- FYI these are labeled for base0 convenience!
            "line0",
            "line1",
            "line2",
            "line3",
            "line4",
            "line5",
            "line6",
            "line7",
            "line8",
            "line9",
        })
    end)

    local one_line_around = 1

    it("middle of a buffer with available context before and after", function()
        local start_line_base0 = 1
        local end_line_exclusive_base0 = 3

        local result = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, one_line_around)

        assert.are.same({
            before = "line0",
            selection = "line1\nline2",
            after = "line3",
        }, result)
    end)

    it("at file beginning (no before context)", function()
        local start_line_base0 = 0
        local end_line_exclusive_base0 = 2

        local result = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, one_line_around)

        assert.are.same({
            before = "",
            selection = "line0\nline1",
            after = "line2",
        }, result)
    end)

    it("at file end (no after context)", function()
        local start_line_base0 = 8
        local end_line_exclusive_base0 = 10 -- FYI line 10 doesn't exist, is exclusive end after last "line 9" (base0)

        local result = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, one_line_around)

        assert.are.same({
            before = "line7",
            selection = "line8\nline9",
            after = "",
        }, result)
    end)
end)
