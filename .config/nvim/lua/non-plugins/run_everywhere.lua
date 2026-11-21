-- Format values in their originating editor, including values RPC cannot encode.
local evaluate = [[
    local function format_returns(...)
        local values = {}
        for i = 1, select("#", ...) do
            local value = select(i, ...)
            values[i] = type(value) == "string" and value or vim.inspect(value)
        end
        return values
    end
    return format_returns(assert(loadstring(..., ":RunEverywhere"))())
]]

local function run_everywhere(source, title, local_last)
    assert(loadstring(source, ":RunEverywhere"))
    local self = vim.fn.getpid()
    local rows = {}
    local pending = 0
    local function record(pid, ok, values)
        rows[pid] = ok and table.concat(values, "  ") or ("Error: " .. tostring(values))
    end

    local function display()
        local messages = require("devtools.messages")
        messages.ensure_open()
        messages.header(title)
        local pids = vim.tbl_keys(rows)
        table.sort(pids)
        for _, pid in ipairs(pids) do
            local label = tostring(pid) .. (pid == self and " (here)" or "")
            messages.append(label .. "  " .. rows[pid])
        end
    end

    local function finish()
        if local_last then record(self, pcall(assert(loadstring(evaluate)), source)) end
        display()
    end

    -- serverlist({ peer = true }) synchronously probes each editor and can hang
    -- while one is waiting at a command prompt. Discover its sockets directly.
    local root = vim.fs.dirname(vim.fn.stdpath("run"))
    local sockets = vim.fn.globpath(root, "*/nvim.*.0", false, true)
    local expression = "json_encode(luaeval(" .. vim.fn.string(
        "assert(loadstring(" .. string.format("%q", evaluate) .. "))(_A)"
    ) .. ", " .. vim.fn.string(source) .. "))"

    for _, address in ipairs(sockets) do
        local pid = tonumber(address:match("/nvim%.(%d+)%.0$"))
        if pid and pid ~= self and vim.uv.kill(pid, 0) == 0 then
            pending = pending + 1
            vim.system({ vim.v.progpath, "--server", address, "--remote-expr", expression },
                { text = true, timeout = 3000 }, vim.schedule_wrap(function(reply)
                    if reply.code == 0 then
                        record(pid, pcall(vim.json.decode, reply.stdout))
                    elseif reply.code == 124 or reply.signal == 15 then
                        rows[pid] = "No reply within 3s (editor may be busy)"
                    else
                        record(pid, false, vim.trim(reply.stderr))
                    end
                    pending = pending - 1
                    if pending == 0 then finish() end
                end))
        end
    end

    if not local_last then record(self, pcall(assert(loadstring(evaluate)), source)) end
    if pending == 0 then finish() end
end

vim.api.nvim_create_user_command("RunEverywhere", function(opts)
    run_everywhere(opts.args, ":RunEverywhere " .. opts.args)
end, { nargs = "+", complete = "lua", desc = "Run Lua in every running Neovim instance" })

vim.api.nvim_create_user_command("NvimInstances", function(opts)
    if opts.args ~= "" then
        local command = opts.args:gsub("^:", "")
        run_everywhere(("vim.cmd(%q)"):format(command), ":NvimInstances " .. opts.args, true)
        return
    end
    run_everywhere([[
        local file = vim.fn.expand("%:p:~")
        return vim.fn.fnamemodify(vim.fn.getcwd(), ":~"), file ~= "" and file or "[No Name]"
    ]], "Neovim instances  |  PID  working directory  active file")
end, { nargs = "*", complete = "command", desc = "List Neovim instances or run an Ex command in each" })
