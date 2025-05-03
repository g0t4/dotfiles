-- I wanna build a list of abbreviations that expand in the command line (mostly to lua) for common things I wanna look up

-- do a video about this too, I only recently realized :abbreviate is a thing (just like fish shell's abbr)

local abbrevs = {
    i = {
        btw = "by the way",
        idk = "I don't know",
    },
    c = {
        wls = "Dump vim.api.nvim_list_wins()",
        bls = "buffers"
    }
}

for mode, defs in pairs(abbrevs) do
    for lhs, rhs in pairs(defs) do
        vim.cmd(string.format("%sabbrev %s %s", mode, lhs, rhs))
    end
end

-- vim.cmd('cabbr wls Dump vim.api.nvim_list_wins()')
