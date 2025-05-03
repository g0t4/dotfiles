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

dump_bufnr = nil
dump_channel = nil

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

    -- create buffer first time
    if dump_bufnr == nil then
        dump_bufnr = vim.api.nvim_create_buf(true, false) -- listed, scratch

        -- * terminal backing:
        -- inspired by `:h TermHl` which also explains the following:
        -- by default, there's no external process
        --   instead it echos input to its STDOUT
        --   STDOUT connects to the buffer so you can see the output in the buffer
        -- KEEP IN MIND: there is no shell running, nor anything else
        --   that would have to be started too, and then connected
        dump_channel = vim.api.nvim_open_term(dump_bufnr, {})
        -- why use a temrinal window?
        --   doesn't have scroll issues like regular buffer
        --   not stuck with scroll until last line in buffer is at topline)
        --   supports ansi color sequences (from my inspect helper)
        --
        -- set modifiable, so I can programatically change (i.e. clear) the buffer
        --   otherwise, by default, terminal buffers are not modifiable
        vim.api.nvim_set_option_value('modifiable', true, { buf = dump_bufnr })

        -- -- * non-terminal backing:
        -- -- set nofile to avoid saving on quit
        -- vim.api.nvim_set_option_value('buftype', 'nofile', { buf = dump_bufnr })

        -- ensure listed w/ name:
        --   I want users to easily find it should they want to
        vim.api.nvim_set_option_value('buflisted', true, { buf = dump_bufnr })
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
    -- TMP this is not here long term, just for now since my original code all assumes buffer opens if not already
    ensure_buffer_is_open() -- TODO! once I figure out how I want it to work in background, then remove this



    -- TODO ok now how can I continue to write to the buffer in the background?
    -- closing it, switching files (buffers) loses its contents since its not a real file

    -- PRN use with my existing Dump command in nvim?
    -- dump into a buffer instead of print/echo/etc
    --    that way I don't need to use `:mess` (and `:mess clear`, etc)

    if not append then
        BufferDumpClear()
    end

    local args = { ... }
    local formatted_args = {}
    for _, arg in ipairs(args) do
        if type(arg) ~= "string" then
            -- inspect anything that isn't a string... inspect returns a string
            arg = vim.inspect(arg)
        end
        -- FYI if I go back to non-terminal backing, need to split on "\n" in each arg too
        table.insert(formatted_args, arg)
    end
    assert(dump_bufnr ~= nil)

    -- * append new content
    --
    -- * terminal buffers:
    -- send output to terminal, so it processes the ANSI color sequences
    -- and output comes over STDOUT back to the buffer
    vim.api.nvim_chan_send(dump_channel, table.concat(formatted_args, "\n") .. "\n")
    --
    -- * non-terminal backing:
    -- vim.api.nvim_buf_set_lines(dump_bufnr, -1, -1, false, lines)
    --   FYI, this can still work on a terminal backed buffer, if it is modifiable
    --   issue is it won't go through the terminal instance for ANSI color sequences to work

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

function BufferDumpHeader(...)
    local header = string.format("%s", table.concat({ ... }, " "))
    header = "\n" .. "---------- " .. header .. " ----------\n"
    buffer_dump_background(true, header)
end

function BufferDump(...)
    buffer_dump_background(false, ...)
end

function BufferDumpClear()
    if dump_bufnr == nil then
        return
    end
    -- * clear the buffer first
    -- both regular and terminal buffers, if modifiable:
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
