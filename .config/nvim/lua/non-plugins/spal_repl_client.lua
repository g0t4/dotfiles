-- lua/ask-openai/helpers/wrap_getpos.lua
require("ask-openai.helpers.wrap_getpos")
local messages = require("devtools.messages")

local M = {}

-- Set these from repl-agent startup log
M.host = "127.0.0.1"
M.port = 8200
-- M.token = "3a2f954e-2d3f-4e6c-af82-555ee7d7d5a7"

local function send_code_to_run(body)
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
                -- vim.notify("REPL: " .. resp)
                messages.header("send_visual_response")
                messages.append(resp)
            end
        end)
    end)
end

function M.send_selected_lines()
    local selection = GetPos.LastSelection()

    -- messages.header("send_visual")
    -- messages.ensure_open()
    -- messages.append(selection)

    local start_line_b0 = selection.start_line_b1 - 1
    local stop_before_b0 = selection.end_line_b1
    local lines = vim.api.nvim_buf_get_lines(0, start_line_b0, stop_before_b0, false)

    messages.append(lines)

    if #lines == 0 then
        print("No lines selected to send")
        return
    end

    send_code_to_run(table.concat(lines, "\n"))
end

function M.send_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    send_code_to_run(table.concat(lines, "\n"))
end

vim.api.nvim_create_user_command("ReplSend", function() M.send_selected_lines() end, { range = true })
vim.api.nvim_create_user_command("ReplSendFile", function() M.send_buffer() end, {})

return M
