--
-- * think of this as devtools for neovim
-- FYI move stable ideas into devtools.nvim repo

-- !! TODO I still stringly feel like the command line in nvim is not right...
--   it needs love somehow... everything feels difficult
--   tab completion doesn't seem to be well thought out...
--   TODO ctrl+R mode (see whole command line not next token?)

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
        -- lnvim = "Dump vim.api.nvim_",


        -- wls = "Dump vim.api.nvim_list_wins()",
        -- bls = "Dump vim.api.nvim_list_bufs()",
        -- bls = "buffers",
        -- tls = "tabs",
    }
}

for mode, defs in pairs(abbrevs) do
    for lhs, rhs in pairs(defs) do
        vim.cmd(string.format("%sabbrev %s %s", mode, lhs, rhs))
    end
end

-- * space-less expansions (abbreviations)
local config = {
    prefixes = {
        -- FYI nvim-cmp already setup to show completions as you type
        --   so no need for <TAB> on end if using nvim-cmp
        --
        -- a regular abbreviation doesn't have aa way to not include the character after that triggered the expansion (i.e. space)
        -- TODO do I like the " " or not...  expand before it instead? or does it feel more natural to expand/"remove" it
        --    both are kinda odd
        --    see what feels right
        --    try each style for a few days and see how it feels
        --
        -- FYI config PLEBS... you want "lua <vim>.<TAB>" ... if you can't handle my :Dump
        ["dvim "] = "Dump vim.",
        ["dts "] = "Dump vim.treesitter.",
        ["=ts "] = "= vim.treesitter.", -- buggy w/o <C-S-U> fix below
        ["dapi "] = "Dump vim.api.",
        ["dfn "] = "Dump vim.fn.",
        -- ["nvim"] = "Dump vim.api.nvim_", -- tab to auto open completion!
        ["nvim "] = "Dump vim.api.nvim_", -- tab to auto open completion!
        ["nml"] = "nmap <leader>",
        -- FYI cannot namespace... they cannot collide at all... without a mechaism to pause and yeah not sure I wanna have that
        -- ["nvimw"] = "Dump vim.api.nvim_win_", -- IOTW nvim here would already expand before I type the w and so
        --     I get "Dump vim.api.nvim_w" ... but that reminds me thats fine by me! I can type the W
        -- ["nvimb"] = "Dump vim.api.nvim_buf_",
    }
}

vim.api.nvim_create_autocmd("CmdlineChanged", {
    pattern = ":",
    callback = function()
        local line = vim.fn.getcmdline()
        for prefix, expansion in pairs(config.prefixes) do
            if line:match("^" .. prefix .. "$") then
                vim.schedule(function()
                    -- FYI! this is a good demo of my message buffer dump tool
                    --   handlers would otherwise require to open messages after every event you want to test
                    --   notify is an alternative but clutters up the screen
                    -- dump.open_append("activated: " .. prefix .. " -> " .. expansion)
                    -- nvim-cmp has <C-u> for smth...

                    -- anyways, I need capital U so if I add shift this seems to work fine
                    -- w/o -S then I get <C-U> activating weird behavior (loops on activating completions w/ nvim-cmp)
                    --    I picked -S... b/c IIUC <C-U>(capital U) should remove all chars from cursor, back to the start of the line
                    --    only happens on some mappings (see above)
                    -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-S-U>" .. expansion, true, false, true))
                    -- FYI if setcmdline works, lets get rid of feedkeys

                    -- FYI alternative... just set the damn commandline
                    vim.fn.setcmdline(expansion)
                    -- PRN could add feeding keys if needed, but I don't need that right now
                    -- and, nvim-cmp still shows completions after setcmdline!
                end)
                break
            end
        end
    end,
})
