-- Xonsh indentation logic.
--
-- Python-style block indentation that is tolerant of xonsh subprocess syntax.
-- Deliberately does NOT scan backwards for brackets/parens (that's what makes
-- python#GetIndent run away on xonsh's $(...)/!(...) lines). Instead it only
-- looks at the immediate previous non-blank line, so indent can never compound.

local M = {}

--- Compute the indent (in spaces) for a line in a xonsh buffer.
---@param lnum? integer line to compute indent for; defaults to v:lnum (indentexpr context)
---@return integer
function M.indent(lnum)
    lnum = lnum or vim.v.lnum

    local prev = vim.fn.prevnonblank(lnum - 1)
    if prev == 0 then
        return 0
    end

    local sw = vim.bo.shiftwidth
    local prev_line = vim.fn.getline(prev)
    local prev_indent = vim.fn.indent(prev)

    -- Dedent when the line being indented already begins with a block-closing
    -- keyword or bracket (e.g. Enter mid-line, or typing `else:`/`return`).
    local cur_line = vim.fn.getline(lnum)
    local first_char = cur_line:match("^%s*(.)")
    local is_closing_bracket = first_char == ")" or first_char == "]" or first_char == "}"
    local first_keyword = cur_line:match("^%s*(%a+)")
    local dedent_keywords = {
        ["else"] = true, ["elif"] = true, ["except"] = true, ["finally"] = true,
        ["return"] = true, ["raise"] = true, ["break"] = true, ["continue"] = true,
        ["pass"] = true,
    }
    if is_closing_bracket or dedent_keywords[first_keyword] then
        return math.max(prev_indent - sw, 0)
    end

    -- Continuation: previous line ends with an unclosed opener (or a backslash).
    -- Only ever adds one level, so it can't run away like python#GetIndent.
    local last_char = prev_line:sub(-1)
    local is_opener = last_char == "(" or last_char == "[" or last_char == "{"
    if is_opener or prev_line:match("\\%s*$") then
        return prev_indent + sw
    end

    -- Block opener: previous line ends with ':'
    if prev_line:match(":%s*$") then
        return prev_indent + sw
    end

    -- Otherwise match the previous line's indent.
    return prev_indent
end

return M
