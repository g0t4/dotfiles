-- Format values in their originating editor, including values RPC cannot encode.
local evaluate = [=[
    local source = ...
    local capture = [[
        local function emit(ok, ...)
            if not ok then
                print("Error: " .. tostring(...))
                return
            end
            local values = {}
            for i = 1, select("#", ...) do
                local value = select(i, ...)
                values[i] = type(value) == "string" and value or vim.inspect(value)
            end
            if #values > 0 then print(table.concat(values, "  ")) end
        end
        emit(pcall(assert(loadstring(%q, ":RunEverywhere"))))
    ]]
    local output = vim.api.nvim_cmd({ cmd = "lua", args = { capture:format(source) } }, { output = true })
    -- Capturing suppresses the original echo. Replay it in this editor as well.
    if output ~= "" then vim.api.nvim_echo({ { output } }, true, {}) end
    return { output }
]=]

local function table_cell(text)
    return (text:gsub("\\", "\\\\"):gsub("|", "\\|"):gsub("[\r\n]+", "<br>"))
end

local function run_everywhere(source, title, local_last, directory, list_instances)
    assert(loadstring(source, ":RunEverywhere"))
    local evaluator = list_instances and "return assert(loadstring(...))()" or evaluate
    if directory then
        -- Check in the target editor immediately before running the command.
        evaluator = ([[
            local cwd = vim.uv.fs_realpath(vim.fn.getcwd())
            local directory = %q
            if not cwd or (cwd ~= directory and not vim.fs.relpath(directory, cwd)) then
                return false
            end
        ]]):format(directory) .. evaluator
    end
    local self = vim.fn.getpid()
    local rows = {}
    local pending = 0
    local function record(pid, ok, values)
        if ok and values == false then return end
        rows[pid] = ok and (list_instances and values or table.concat(values, "  ")) or ("Error: " .. tostring(values))
    end

    local function display()
        local messages = require("devtools.messages")
        messages.ensure_open()
        messages.header(title)
        if not next(rows) then
            messages.append("No matching instances")
            return
        end
        if list_instances then
            messages.append("")
            messages.append("| PID | Working directory | Active file |")
            messages.append("| --- | --- | --- |")
        end
        local pids = vim.tbl_keys(rows)
        table.sort(pids)
        for _, pid in ipairs(pids) do
            local label = tostring(pid) .. (pid == self and " (here)" or "")
            local row = rows[pid]
            if list_instances then
                local cells = type(row) == "table" and row or { "", row }
                messages.append(("| %s | %s | %s |"):format(label, table_cell(cells[1]), table_cell(cells[2])))
            else
                messages.append(label .. "  " .. row)
            end
        end
    end

    local function finish()
        if local_last then record(self, pcall(assert(loadstring(evaluator)), source)) end
        display()
    end

    -- serverlist({ peer = true }) synchronously probes each editor and can hang
    -- while one is waiting at a command prompt. Discover its sockets directly.
    local root = vim.fs.dirname(vim.fn.stdpath("run"))
    local sockets = vim.fn.globpath(root, "*/nvim.*.0", false, true)
    local expression = "json_encode(luaeval(" .. vim.fn.string(
        "assert(loadstring(" .. string.format("%q", evaluator) .. "))(_A)"
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

    if not local_last then record(self, pcall(assert(loadstring(evaluator)), source)) end
    if pending == 0 then finish() end
end

vim.api.nvim_create_user_command("RunEverywhere", function(opts)
    local source = opts.args:gsub("^%s*=", "return ", 1)
    run_everywhere(source, ":RunEverywhere " .. opts.args)
end, { nargs = "+", complete = "lua", desc = "Run Lua in every running Neovim instance" })

local function instances(command, title, directory)
    if command ~= "" then
        run_everywhere(("vim.cmd(%q)"):format(command), title, true, directory)
        return
    end
    run_everywhere([[
        local cwd = vim.fn.getcwd()
        local file = vim.api.nvim_buf_get_name(0)
        local path = file ~= "" and (vim.fs.relpath(cwd, file) or file) or "[No Name]"
        return { vim.fn.fnamemodify(cwd, ":~"), path }
    ]], title, false, directory, true)
end

vim.api.nvim_create_user_command("NvimInstances", function(opts)
    instances(opts.args:gsub("^:", ""), ":NvimInstances " .. opts.args)
end, { nargs = "*", complete = "command", desc = "List Neovim instances or run an Ex command in each" })

vim.api.nvim_create_user_command("NvimInstancesCWD", function(opts)
    -- A colon starts the Ex command, so the directory can contain spaces.
    local path, command
    if vim.startswith(opts.args, ":") then
        path, command = "", opts.args:sub(2)
    else
        path, command = opts.args:match("^(.-)%s+:(.*)$")
        if not path then path, command = opts.args, "" end
    end
    path = path ~= "" and vim.fn.fnamemodify(path, ":p") or vim.fn.getcwd()
    local directory = vim.uv.fs_realpath(path)
    if not directory or vim.fn.isdirectory(directory) == 0 then
        error("Directory does not exist: " .. path)
    end
    instances(command, ":NvimInstancesCWD " .. directory .. " :" .. command, directory)
end, { nargs = "*", desc = "List or command instances under [directory] [:Ex command]" })

vim.keymap.set("n", "<leader>ni", "<Cmd>NvimInstances<CR>", { desc = "List Neovim instances" })
vim.keymap.set("n", "<leader>niw", "<Cmd>NvimInstancesCWD<CR>", { desc = "List Neovim instances in this workspace" })
