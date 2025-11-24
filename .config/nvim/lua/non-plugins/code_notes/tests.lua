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

    local ONE_LINE_AROUND = 1
    local THREE_LINES_AROUND = 3

    it("near start, with only context before selection", function()
        local start_line_base0 = 1
        local end_line_exclusive_base0 = 3

        local context = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, ONE_LINE_AROUND)

        assert.are.same({
            before = "line0",
            selection = "line1\nline2",
            after = "line3",
        }, context)
    end)

    it("middle of a buffer with 3 lines of context (not touching start/end of buffer)", function()
        local start_line_base0 = 4
        local end_line_exclusive_base0 = 5

        local context = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, THREE_LINES_AROUND)

        assert.are.same({
            before = "line1\nline2\nline3",
            selection = "line4",
            after = "line5\nline6\nline7",
        }, context)
    end)

    it("at file beginning (no before context)", function()
        local start_line_base0 = 0
        local end_line_exclusive_base0 = 2

        local context = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, ONE_LINE_AROUND)

        assert.are.same({
            before = "",
            selection = "line0\nline1",
            after = "line2",
        }, context)
    end)

    it("at file end (no after context)", function()
        local start_line_base0 = 8
        local end_line_exclusive_base0 = 10 -- FYI line 10 doesn't exist, is exclusive end after last "line 9" (base0)

        local context = M.slice(bufnr, start_line_base0, end_line_exclusive_base0, ONE_LINE_AROUND)

        assert.are.same({
            before = "line7",
            selection = "line8\nline9",
            after = "",
        }, context)
    end)
end)
