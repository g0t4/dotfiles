
-- *** :Dump vim.g.foo
-- TODO completion for <args>, lua expression completion
-- Am I the only who hates typing :lua print(vim.inspect(...))?
vim.api.nvim_create_user_command('Dump', "lua print(vim.inspect(<args>))", {
    nargs = '*',
    complete = "lua", -- completes like using :lua command
})
-- vim.cmd [[
--     command! -nargs=1 -complete=lua Dump lua print(vim.inspect(<args>))
-- ]]
--

function _BufferDumpTest()
    local inspected = vim.inspect({ a = "foo", b = "bar" })
    splitted = vim.split(inspected, "\n")
    BufferDump(splitted, splitted)
end

local function is_buffer_visible(bufnr)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
            return true
        end
    end
    return false
end

function BufferDump(...)
    _BufferDump(false, ...)
end

function BufferDumpAppend(...)
    _BufferDump(true, ...)
end

local dump_bufnr = nil
function _BufferDump(append, ...)
    -- TODO use with existing Dump?
    -- dump into a buffer instead of print/echo/etc
    --    that way I don't need to use `:mess` (and `:mess clear`, etc)

    if dump_bufnr == nil then
        dump_bufnr = vim.api.nvim_create_buf(false, true)
    end

    -- ensure buffer is visible
    -- vim.api.nvim_win_set_buf(0, bufnr)
    if not is_buffer_visible(dump_bufnr) then
        vim.api.nvim_command("vsplit")
        vim.api.nvim_win_set_buf(0, dump_bufnr)
    end

    local args = { ... }
    local lines = {}
    for _, arg in ipairs(args) do
        if type(arg) == "string" then
            -- leave strings as is
            table.insert(lines, arg)
        else
            -- inspect everything else (tables, etc)
            local inspected = vim.inspect(arg)
            local splitted = vim.split(inspected, "\n")
            for _, line in ipairs(splitted) do
                table.insert(lines, line)
            end
        end
    end

    if append then
        vim.api.nvim_buf_set_lines(dump_bufnr, -1, -1, false, lines)
    else
        -- overwrite
        vim.api.nvim_buf_set_lines(dump_bufnr, 0, -1, false, lines)
    end

    -- move cursor to bottom of buffer
    vim.api.nvim_feedkeys("G", "n", true)
end


