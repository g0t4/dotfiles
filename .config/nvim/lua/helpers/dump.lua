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

---@return integer|nil # first window_id for buffer
local function window_id_for_buffer(bufnr)
    local window_ids = vim.fn.win_findbuf(bufnr)
    -- FYI list is empty if no matches
    return window_ids[1]
end

local function is_buffer_visible(bufnr)
    local window_id = window_id_for_buffer(bufnr)
    return window_id ~= nil
end

local dump_bufnr = nil

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

local function ensure_buffer_is_open()
    -- note the current window so I can switch back to it when done opening the buffer/window
    local original_window_id = vim.api.nvim_get_current_win()

    -- TODO extract a buffer helper class so I can reuse a set of methods around creating and using buffers
    --   TODO! set names for these, like Zed has its Zed log, vs LSP logs, etc... I can log to in-memory buffers and open when I wanna see them
    -- create buffer first time
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

    vim.api.nvim_set_current_win(original_window_id)
end
local function buffer_dump(append, ...)
    ensure_buffer_is_open()
    buffer_dump_background(append, ...)
end
function buffer_dump_background(append, ...)
    -- PRN use with my existing Dump command in nvim?
    -- dump into a buffer instead of print/echo/etc
    --    that way I don't need to use `:mess` (and `:mess clear`, etc)

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
    assert(dump_bufnr ~= nil)

    if append then
        vim.api.nvim_buf_set_lines(dump_bufnr, -1, -1, false, lines)
    else
        -- overwrite
        vim.api.nvim_buf_set_lines(dump_bufnr, 0, -1, false, lines)
    end

    -- move cursor to bottom of buffer
    local dump_window_id = window_id_for_buffer(dump_bufnr)
    assert(dump_window_id ~= nil)
    vim.fn.win_execute(dump_window_id, "normal G")
end

--- FYI this only APPENDS (for now)
function BufferDumpArray(array)
    -- pass an array table that explicitly should be dumped with one item per line
    -- otherwise, vim.inspect will collapse onto one line... perhaps vim.inspect has flags to pass?
    -- ** SUPER USEFUL vim.iter
    vim.iter(array):each(function(_index, item)
        BufferDumpAppend(item)
    end)
end

function BufferDump(...)
    buffer_dump_background(false, ...)
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
    -- assume buffer is open (or explicitly closed) and its fine to append w/o a care for showing it
    buffer_dump_background(true, ...)
end

function BufferDumpOpen()
    ensure_buffer_is_open()
end

---@return integer|nil bufnr, integer|nil window_id
function GetBufferDumpNumbers()
    if dump_bufnr == nil then
        return nil, nil
    end
    -- for special cases where I just wanna reuse this buffer
    return dump_bufnr, window_id_for_buffer(dump_bufnr)
end
