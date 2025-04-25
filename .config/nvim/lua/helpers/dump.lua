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
    local inspected = { a = "foo", b = "bar" }
    BufferDump(inspected, inspected)
end

local function is_buffer_visible(bufnr)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
            return true
        end
    end
    return false
end

local dump_bufnr = nil

function BufferDump(...)
    _BufferDump(false, ...)
end

function BufferDumpClear()
    if dump_bufnr == nil then
        return
    end
    -- FYI doesn't matter if buffer is visible, just clear it even if hidden...
    -- PRN if I want to make sure it shows too, then add that semantic, but for now clear alone is fine
    vim.api.nvim_buf_set_lines(dump_bufnr, 0, -1, false, {})
end

function BufferDumpAppend(...)
    _BufferDump(true, ...)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        -- FYI if this happens AFTER session save autocmd (also triggers on VimLeavePre) then the BufferDump will still restore...
        --   lets deal with that if it happens as it will be obvious... for now the order works out fine
        --   Alternative is to call this from werkspace VimLeavePre to ensure its called in right order
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_name(buf):match("buffer_dump") then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end,
})

function _BufferDump(append, ...)
    -- TODO use with existing Dump?
    -- dump into a buffer instead of print/echo/etc
    --    that way I don't need to use `:mess` (and `:mess clear`, etc)

    if dump_bufnr == nil then
        dump_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(dump_bufnr, 'buffer_dump')
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
        if type(arg) ~= "string" then
            -- inspect anything that isn't a string... inspect returns a string
            arg = vim.inspect(arg)
        end
        splitted = vim.split(arg, "\n")
        for _, line in ipairs(splitted) do
            table.insert(lines, line)
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
