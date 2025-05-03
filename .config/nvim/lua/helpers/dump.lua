-- * DumpBuffer module
local M = {}

-- FYI if you want an nvim user_command that takes a lua expression
--    and it gets the evaluated value... this is how you can do it
--
vim.api.nvim_create_user_command("Dump", function(opts)
    M.ensure_open()

    -- PRN retire this message later on
    M.append("FYI use `:=` command to dump to the command line, instead of here")

    -- FYI should only be one expression
    --   there wouldn't be completion for multiple
    --   what would a commma mean?
    --   conversely, can pass a table for multiple expressions

    -- * evaluate lua expression
    local chunk, err = load("return " .. opts.args)
    if not chunk then
        error("Invalid expression: " .. err)
    end
    local ok, result = pcall(chunk)
    if not ok then
        error("Error during evaluation: " .. result)
    end

    M.header("Expression: " .. opts.args)
    M.append(vim.inspect(result))
    --
end, {
    nargs = '*',
    complete = "lua", -- completes like using :lua command!
})
-- b/c not allowed to use lowercase command names:
vim.cmd [[ cabbrev dump Dump ]]
vim.cmd [[ cabbrev DUmp Dump ]] -- frequently mistype, b/c I have to capitalize the goddamn D
-- FYI original vimscript definition:
-- vim.cmd [[
--     command! -nargs=1 -complete=lua Dump lua print(vim.inspect(<args>))
-- ]]




M.dump_bufnr = nil
M.dump_channel = nil

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

---@return integer|nil # first window_id for buffer
local function window_id_for_buffer(bufnr)
    local window_ids = vim.fn.win_findbuf(bufnr)
    -- FYI list is empty if no matches
    return window_ids[1]
end

function M.is_visible(bufnr)
    local window_id = window_id_for_buffer(bufnr)
    return window_id ~= nil
end

--- does not open the buffer
--- only creates it if it doesn't already exist
local function ensure_buffer_exists()
    if M.dump_bufnr ~= nil then
        return
    end

    -- create buffer first time
    M.dump_bufnr = vim.api.nvim_create_buf(true, false) -- listed, scratch

    -- * terminal backing:
    -- inspired by `:h TermHl` which also explains the following:
    -- by default, there's no external process
    --   instead it echos input to its STDOUT
    --   STDOUT connects to the buffer so you can see the output in the buffer
    -- KEEP IN MIND: there is no shell running, nor anything else
    --   that would have to be started too, and then connected
    M.dump_channel = vim.api.nvim_open_term(M.dump_bufnr, {})
    -- why use a temrinal window?
    --   doesn't have scroll issues like regular buffer
    --   not stuck with scroll until last line in buffer is at topline)
    --   supports ansi color sequences (from my inspect helper)
    --
    -- set modifiable, so I can programatically change (i.e. clear) the buffer
    --   otherwise, by default, terminal buffers are not modifiable
    vim.api.nvim_set_option_value('modifiable', true, { buf = M.dump_bufnr })

    -- -- * non-terminal backing:
    -- -- set nofile to avoid saving on quit
    -- vim.api.nvim_set_option_value('buftype', 'nofile', { buf = dump_bufnr })

    -- ensure listed w/ name:
    --   I want users to easily find it should they want to
    vim.api.nvim_set_option_value('buflisted', true, { buf = M.dump_bufnr })
    vim.api.nvim_buf_set_name(M.dump_bufnr, 'buffer_dump')
end

local function ensure_buffer_is_open()
    ensure_buffer_exists()

    -- TODO! test this works here after creating buffer (before opening it in a window)
    -- note the current window so I can switch back to it when done opening the buffer/window
    local original_window_id = vim.api.nvim_get_current_win()

    -- ensure buffer is visible
    if not M.is_visible(M.dump_bufnr) then
        vim.api.nvim_command("vsplit")
        vim.api.nvim_win_set_buf(0, M.dump_bufnr)
    end

    vim.api.nvim_set_current_win(original_window_id)
end

local function dump_background(...)
    -- TMP this is not here long term, just for now since my original code all assumes buffer opens if not already
    ensure_buffer_exists()
    assert(M.dump_bufnr ~= nil)

    local args = { ... }
    for _, arg in ipairs(args) do
        if type(arg) ~= "string" then
            -- inspect anything that isn't a string... inspect returns a string
            arg = vim.inspect(arg)
        end


        -- * append new content
        -- ** terminal buffers:
        -- send output to terminal, so it processes the ANSI color sequences
        -- and output comes over STDOUT back to the buffer
        -- vim.api.nvim_chan_send(dump_channel, table.concat(formatted_args, "\n") .. "\n")
        vim.api.nvim_chan_send(M.dump_channel, arg .. "\n")

        -- * non-terminal backing:
        -- FYI had to split on "\n" for each arg too, so every line is separate
        --   vim.api.nvim_buf_set_lines(dump_bufnr, -1, -1, false, lines)
        -- OR can try using nvim_buf_
        --   vim.api.nvim_buf_set_text(dump_bufnr, -1, 0, { arg })
        -- FYI, this can still work on a terminal backed buffer, if it is modifiable
        --   issue is it won't go through the terminal instance for ANSI color sequences to work
    end

    -- TODO not working with term backed buffer?
    -- if window is open, scroll to bottom
    local dump_window_id = window_id_for_buffer(M.dump_bufnr)
    if dump_window_id == nil then
        return
    end
    vim.fn.win_execute(dump_window_id, "normal G")
end

function M.header(...)
    ensure_buffer_exists()

    local header = string.format("%s", table.concat({ ... }, " "))
    header = "\n" .. "---------- " .. header .. " ----------\n"
    dump_background(true, header)

    return M
end

function M.clear()
    if M.dump_bufnr == nil then
        return
    end

    -- both regular and terminal buffers, if modifiable:
    vim.api.nvim_buf_set_lines(M.dump_bufnr, 0, -1, false, {})

    return M
end

function M.append(...)
    -- assume buffer is open (or explicitly closed) and its fine to append w/o a care for showing it
    dump_background(true, ...)

    return M
end

function M.ensure_open()
    ensure_buffer_is_open()

    return M
end

---@return integer|nil bufnr, integer|nil window_id
function M.get_ids()
    if M.dump_bufnr == nil then
        return nil, nil
    end
    -- for special cases where I just wanna reuse this buffer
    -- probably shouldn't be using it for other things :)
    return M.dump_bufnr, window_id_for_buffer(M.dump_bufnr)
end

return M
