--
-- * think of this as devtools for neovim

local function alias(lower, original)
    vim.cmd(string.format("cabbrev %s %s", lower, original))
end

-- * :windows
vim.api.nvim_create_user_command("Windows", function()
    local windows = vim.api.nvim_list_wins()

    -- vim.api.nvim_win_get_config(0)
    -- {
    --   external = false,
    --   focusable = true,
    --   height = 56,
    --   hide = false,
    --   mouse = true,
    --   relative = "",
    --   split = "left",
    --   width = 120
    -- }

    local info    = vim.iter(windows)
        :map(function(window_id)
            local config = vim.api.nvim_win_get_config(window_id)
            local bufnr = vim.api.nvim_win_get_buf(window_id)
            -- PRN based on buf/filetype ... display different info?
            -- local buftype = vim.bo[bufnr].buftype
            -- local filetype = vim.bo[bufnr].filetype
            local buflines = vim.api.nvim_buf_line_count(bufnr)
            local name = vim.api.nvim_buf_get_name(bufnr)
            local row, col = unpack(vim.api.nvim_win_get_cursor(window_id))
            return window_id .. " " .. config.split
                .. " → buf " .. bufnr .. ": " .. name
                .. " @ row: " .. row .. "/" .. buflines
                .. "  col: " .. col
        end)
        :join("\n")

    vim.print(info)
end, {})
alias("windows", "Windows")

-- ! do a video about this too, I only recently realized :abbreviate is a thing (just like fish shell's abbr)

local abbrevs = {
    i = {
        btw = "by the way",
        idk = "I don't know",
    },
    c = {
        wls = "Dump vim.api.nvim_list_wins()",
        bls = "Dump vim.api.nvim_list_bufs()",
        -- bls = "buffers",
        tls = "tabs",
    }
}

for mode, defs in pairs(abbrevs) do
    for lhs, rhs in pairs(defs) do
        vim.cmd(string.format("%sabbrev %s %s", mode, lhs, rhs))
    end
end

-- vim.cmd('cabbr wls Dump vim.api.nvim_list_wins()')
