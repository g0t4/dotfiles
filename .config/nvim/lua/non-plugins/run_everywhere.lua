vim.api.nvim_create_user_command("RunEverywhere", function(opts)
    local run = assert(loadstring(opts.args, ":RunEverywhere"))
    local self = vim.fn.getpid()
    local seen = { [self] = true }
    local errors = {}
    local count = 0

    for _, address in ipairs(vim.fn.serverlist({ peer = true })) do
        if not vim.tbl_contains(vim.fn.serverlist(), address) then
            local channel
            local ok, err = pcall(function()
                channel = vim.fn.sockconnect("pipe", address, { rpc = true })
                assert(channel > 0, "could not connect")
                local pid = vim.rpcrequest(channel, "nvim_call_function", "getpid", {})
                if not seen[pid] then
                    seen[pid] = true
                    -- Discard the chunk's return value, which may not be RPC-serializable.
                    vim.rpcrequest(channel, "nvim_exec_lua", "assert(loadstring(...))()", { opts.args })
                    count = count + 1
                end
            end)
            if channel and channel > 0 then vim.fn.chanclose(channel) end
            if not ok then table.insert(errors, address .. ": " .. tostring(err)) end
        end
    end

    local ok, err = pcall(run)
    if ok then
        count = count + 1
    else
        table.insert(errors, "current instance: " .. tostring(err))
    end

    local summary = ("Ran Lua in %d Neovim instance(s)"):format(count)
    if #errors > 0 then error(summary .. "\n" .. table.concat(errors, "\n")) end
    print(summary)
end, { nargs = "+", desc = "Run Lua in every running Neovim instance" })
