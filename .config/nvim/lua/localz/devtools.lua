--
-- * think of this as devtools for neovim
-- yes abbrs will be part of it
-- also wanna add things to inspect easily... like
-- :windows command
vim.api.nvim_create_user_command("Windows", function()
    local windows = vim.api.nvim_list_wins()
    vim.print(windows)
end, {})
local function alias(lower, original)
    vim.cmd(string.format("cabbrev %s %s", lower, original))
end
alias("windows", "Windows")

-- I wanna build a list of abbreviations that expand in the command line (mostly to lua) for common things I wanna look up

-- do a video about this too, I only recently realized :abbreviate is a thing (just like fish shell's abbr)

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
