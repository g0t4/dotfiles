--
-- * think of this as devtools for neovim
-- ***! STOP FUMBLING AROUND with typing :Dump/:lua vim.api... nonsense


-- !! TODO I still stringly feel like the command line in nvim is not right...
--   it needs love somehow... everything feels difficult
--   tab completion doesn't seem to be well thought out...
--   TODO ctrl+R mode (see whole command line not next token?)

-- ! do a video about this too, I only recently realized :abbreviate is a thing (just like fish shell's abbr)

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



local abbrevs = {
    i = {
        btw = "by the way",
        idk = "I don't know",
    },
    c = {
        -- TODO how can I get rid of the space after expanding? in just this case?
        lapi = "Dump vim.api",
        lnvim = "Dump vim.api.nvim_",


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



-- * abbreviations that expand on space, that then remove the space
-- ok I really like `lapi` already!
local config = {
    prefixes = {
        ["lapi"] = "Dump vim.api."
    }
}

vim.api.nvim_create_autocmd("CmdlineChanged", {
    pattern = ":",
    callback = function()
        local line = vim.fn.getcmdline()
        for prefix, expansion in pairs(config.prefixes) do
            if line:match("^" .. prefix .. "$") then
                -- Replace whole cmdline with "bar"
                vim.schedule(function()
                    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-U>" .. expansion, true, false, true))
                end)
                break
            end
        end
    end,
})

-- vim.keymap.set('c', 'jj', function()
--     --- getcmdline is empty... needs to use <C-\>e to eval expression right?
--     local line = vim.fn.getcmdline()
--     local pos = vim.fn.getcmdpos()
--     vim.schedule(function()
--         vim.notify(line)
--     end)
--     if line:sub(pos - 2, pos - 1) == 'jj' then
--         return vim.api.nvim_replace_termcodes('<C-U>bar', true, false, true)
--     end
--     return 'jj'
-- end, { expr = true })

-- vim.keymap.set('i', 'jj', function()
--     local col = vim.fn.col('.') - 1
--     local line = vim.fn.getline('.')
--     if col >= 2 and line:sub(col - 1, col) == 'jj' then
--         return vim.api.nvim_replace_termcodes('<BS><BS>bar', true, false, true)
--     end
--     return 'jj'
-- end, { expr = true })
