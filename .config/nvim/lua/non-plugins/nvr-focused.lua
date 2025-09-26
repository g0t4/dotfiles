do return end

-- Use this to send commands without pointless keymaps or typing out keys -- i.e. from streamdeck=>KM/HS=>this

-- command to focused nvim instance:
--
-- addr_file="$HOME/.cache/nvim/nvim-last-focused-addr"
-- [ -s "$addr_file" ] && nvr --nostart --server "$(cat "$addr_file")" --remote-expr '1'
--
-- OR:
-- nvr --nostart --server "$(cat ~/.cache/nvim/nvim-last-focused-addr)" -c 'lua print(vim.fn.stdpath("cache"))'

local uv = vim.loop
local pid = uv.getpid()
local addr = string.format("%s/nvim-%d.sock", vim.fn.stdpath("run"), pid)
vim.fn.serverstart(addr)

local nvim_last_focused_file = vim.fn.stdpath("cache") .. "/nvim-last-focused-addr"

local function write_info()
    local fd, err = uv.fs_open(nvim_last_focused_file, "w", 420) -- 420 = 0644
    if not fd then
        vim.notify("fs_open failed: " .. err, vim.log.levels.ERROR)
        return
    end
    uv.fs_write(fd, addr, -1, function(write_err)
        if write_err then
            vim.notify("fs_write failed: " .. write_err, vim.log.levels.ERROR)
        end
        uv.fs_close(fd)
    end)
end

write_info()

vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
        write_info()
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        -- on exit
        -- clear address from file if it's still the current address
        -- which is likely on exit
        -- consumers can use empty file = no focused instance instead of trying a missing socket
        local data = vim.fn.readfile(nvim_last_focused_file)[1]
        if data == addr then
            uv.fs_unlink(nvim_last_focused_file)
        end
    end,
})
