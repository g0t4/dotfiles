local M = {}

-- Set these from your agent log
M.host = "127.0.0.1"
M.port = 8200
-- M.token = "3a2f954e-2d3f-4e6c-af82-555ee7d7d5a7"

local function send_text(body)
    local uv = vim.loop
    local tcp = uv.new_tcp()
    tcp:connect(M.host, M.port, function(err)
        if err then
            vim.notify("REPL connect failed: " .. err, vim.log.levels.ERROR); return
        end
        local payload = table.concat({
            -- M.token,
            body, "."
        }, "\n") .. "\n"
        tcp:write(payload)
        local chunks = {}
        tcp:read_start(function(read_err, chunk)
            if read_err then vim.notify("REPL read error: " .. read_err, vim.log.levels.ERROR) end
            if chunk then
                table.insert(chunks, chunk)
            else
                tcp:shutdown(function() tcp:close() end)
                local resp = (table.concat(chunks)):gsub("%s+$", "")
                vim.notify("REPL: " .. resp)
            end
        end)
    end)
end

function M.send_visual()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
    if #lines == 0 then return end
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    send_text(table.concat(lines, "\n"))
end

function M.send_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    send_text(table.concat(lines, "\n"))
end

vim.api.nvim_create_user_command("ReplSend", function() M.send_visual() end, { range = true })
vim.api.nvim_create_user_command("ReplSendFile", function() M.send_buffer() end, {})

return M
