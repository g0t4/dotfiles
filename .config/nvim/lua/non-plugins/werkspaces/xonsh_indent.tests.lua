require("tests.setup").modify_package_path()
local assert = require("luassert")
local buffers = require("devtools.tests.buffers")
-- system under test:
local M = require("non-plugins.werkspaces.xonsh_indent")

describe("xonsh_indent", function()
    local bufnr

    before_each(function()
        bufnr = buffers.new_buffer_with_lines({})
        vim.bo.shiftwidth = 4
    end)

    local function indent_at(lines, target_lnum)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        return M.indent(target_lnum)
    end

    it("indents after a block opener (line ending in ':')", function()
        -- line 2 is the empty line right after `def foo():`
        assert.equal(4, indent_at({ "def foo():", "" }, 2))
        assert.equal(8, indent_at({ "    def foo():", "" }, 2))
    end)

    it("matches the previous line's indent for plain statements", function()
        assert.equal(4, indent_at({ "def foo():", "    x = 1", "" }, 3))
    end)

    it("indents after an unclosed bracket/paren opener", function()
        assert.equal(4, indent_at({ "func(", "" }, 2))
        assert.equal(4, indent_at({ "d = {", "" }, 2))
        assert.equal(4, indent_at({ "items = [", "" }, 2))
    end)

    it("matches the continuation line's indent inside parens", function()
        assert.equal(4, indent_at({ "func(", "    arg1,", "" }, 3))
    end)

    it("dedents on a closing bracket", function()
        assert.equal(0, indent_at({ "func(", "    arg1,", ")" }, 3))
    end)

    it("dedents on block-closing keywords", function()
        assert.equal(0, indent_at({ "def foo():", "    x = 1", "else:" }, 3))
        assert.equal(0, indent_at({ "def foo():", "    return" }, 2))
    end)

    it("returns 0 at the start of the buffer", function()
        assert.equal(0, indent_at({ "def foo():" }, 1))
        assert.equal(0, indent_at({ "" }, 1))
    end)
end)
