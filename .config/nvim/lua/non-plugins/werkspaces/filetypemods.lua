-- FYI if issues with werkspace not having these options set... that can happen if this is registered after werkspaces are loaded
--
--
-- NOTES:
--   use buffer local variables in filetype mods

-- *** FORMAT indents
-- gg=G - runs formatter (indent)
--  indentexpr can be set for that too (mine defaults to treesitter's indent

-- *** GLOBAL OPTION DEFAULTS ***
-- FYI global defaults need to be applied BEFORE WERKSPACE RESTORE... else those files restore before this and then these mess up the restored files/windows... (globals must come first)... what happens is then this fubars the coc/format settings that somehow override (IIUC) based on things like luarc
--    SO, if :TroubleshootOptions shows diff option values... and then :e! and :TroubleshootOptions again shows correct (diff) values... for restored files... likely the issue is with ordering of these globals/filetype overrides
--
-- *** wrap global defaults
vim.o.wrap = false -- global nowrap, consider local settings for this instead
vim.o.textwidth = 0 -- disable globally, add back if I find myself missing it
vim.o.wrapmargin = 0 -- disable globally, add back if I find myself missing it

-- *** tab global defaults (then filetype/coc should override these) - only plan to use these if you don't have formatter setup for a given filetype that feeds back into these values
-- I chose option 2 (always insert spaces, leave tabs as is with default tabstop=8)
vim.o.expandtab = true -- insert spaces for tabs
vim.o.softtabstop = 4 -- b/c expandtab is set, this is the width of an inserted tab in spaces
vim.o.shiftwidth = 4 -- shifting: << >>
-- vim.o.tabstop -- leave as is (8) so existing uses of tabs match width likely intended

-- *** show whitespace
vim.opt.listchars = { tab = '→ ', trail = '·', space = '⋅' } -- FYI also `eol:$`
vim.cmd([[
    command! ToggleShowWhitespace if &list | set nolist | else | set list | endif
]])

-- *** notes == md
--     so I can stop putting notes.md on the end of files
vim.filetype.add({
    extension = {
        notes = "markdown",
        harmony = "harmony",
        --
        -- override bash as bash...
        -- FYI this should be the case from the nvim runtime files (but somehow nvim runtime seems to assign sh instead)
        -- bash = "bash",
        -- fuck.. coc-sh only recognizes .sh ... leave this off for now ... I need to just use bash LS directly
        --   and then also setup format to use shfmt (just override keymap for .bash files is fine IMO)
        --   see more notes in coc-settings.json...
    },
})

-- -- *** jsonc doesn't spam about comments (while coc-json still seems to provide services, notably schema completion)
-- --  map a few key files that are heavily commented here so if I re-enable validation (disagnostics) for json then these are still ok
-- -- FYI confirmed coc-json still works with jsonc:
-- --       https://github.com/neoclide/coc-json/blob/master/server/jsonServer.ts#L357
-- --       why didn't they make the options configurable though?!
-- vim.filetype.add({
--     pattern = {
--         [".*%.luarc%.json"] = "jsonc",
--     },
-- })


local function describeFormatOptionForLetter(letter)
    local descriptions = {

        -- auto-wrap:
        ["c"] = "auto-wrap comments", -- on textwidth?
        ["t"] = "auto-wrap text", -- on textwidth?
        ["l"] = "do not wrap in insert mode",

        -- comment leader:
        ["o"] = "insert comment leader on `o` and `O`",
        ["r"] = "insert comment leader on <Enter>",
        ["j"] = "remove comment leader on [J]oin",

        -- misc:
        ["a"] = "auto-format paragraphs",
        ["q"] = "gq formats comments",
        ["n"] = "format recognizes numbered lists", -- TODO OMG this sounds like what I wanted! for lists in comments?
    }
    return descriptions[letter] or letter
end

local function printFormatOptions()
    local enabled_letters = vim.opt.formatoptions._value

    local message = ""
    local function forLetter(letter)
        if enabled_letters:find(letter) then
            message = message .. "    " .. letter .. " - " .. describeFormatOptionForLetter(letter) .. "\n"
        end
        -- optional => else => show disabled in group at end of section? add forGroup("wrapping related", "ctl")?
    end

    -- instead of a loop, I want to control of grouping/sorting
    -- instead of a loop, I want to control of the foo the bar

    message = message .. "  auto-wrap:\n"
    forLetter("c")
    forLetter("t")
    forLetter("l")

    message = message .. "  comments:\n"
    forLetter("o")
    forLetter("r")
    forLetter("j")
    message = message .. "    note: Ctrl-U removes leader\n"

    message = message .. "  formatting:\n"
    forLetter("q")
    forLetter("a")
    forLetter("n")

    print(message)
end

-- *** command to show tab config (print messages)
vim.api.nvim_create_user_command('TroubleshootOptions', function()
    -- invaluable to troubleshoot script ordering issues b/c I can quickly see what is what after rearranges
    -- sometimes things are misconfigured and I wanna dump the config all at once that is likely affected (i.e. my werkspace plugin, the lua file loaded doesn't seem to apply the editorconfig values for lua but if I :e! then it does)
    -- expandtab == true => insert spaces for tabs (used w/ < > commands and when autoindent=on)
    --
    print(
    -- print first so it doesn't show unless :messages
        "wrap:" .. tostring(vim.o.wrap),
        "wrapmargin:" .. tostring(vim.o.wrapmargin),
        "textwidth:" .. tostring(vim.o.textwidth),
        "linebreak:" .. tostring(vim.o.linebreak),
        " - "
    )
    -- ok to have super wide output... most of the time I have full screen width... and zoomed small
    print("expandtab:" .. tostring(vim.o.expandtab),
        "softtabstop:" .. tostring(vim.o.softtabstop),
        "shiftwidth:" .. tostring(vim.o.shiftwidth),
        "tabstop:" .. tostring(vim.o.tabstop),
        " - ",
        "autoindent:" .. tostring(vim.o.autoindent),
        "smartindent:" .. tostring(vim.o.smartindent),
        "cindent:" .. tostring(vim.o.cindent),
        "smarttab:" .. tostring(vim.o.smarttab)
    )

    print("formatoptions:", vim.opt.formatoptions._value)
    printFormatOptions()
end, { bang = true })

-- PRN review `autoindent`/`smartindent`/`cindent` and `smarttab` settings
--     filetype plugin indent on " this is controlling indent on new lines for now and seems fine so leave it as is
--     set backspace=indent,start,eol " allow backspacing over everything in insert mode, including indent from autoindent, eol thru start of insert

vim.api.nvim_create_augroup("filetypemods", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    group = "filetypemods",
    callback = function()
        -- FYI subsequent autocmds can override this... so careful with printing out current settings cuz it might be interim

        -- *** global defaults ***
        --   using autocmd on BufEnter to override all init.lua config settings for this (including after ftplugins)
        local opts = vim.opt.formatoptions._value -- use a FUCKING string... whoever came up with this fucking multi-value option should be raped and shot and then raped again
        -- print("filetypemods - initial formatoptions:", opts)

        -- auto-wrap on textwidth:
        --   I HATE auto wrapping... especially for comments
        --   You might convince me to wrap code/text automatically if it is smart about how it decides... but sometimes I want a long line of code too (or comment at end)
        opts = opts:gsub("c", "") --  wrapping comments on textwidth
        opts = opts:gsub("t", "") --  wrapping regular text on textwidth
        opts = opts .. "l" --  do not wrap in insert mode (when past textwidth columns) - was already default, just make explicit

        -- comment leaders:
        --   FYI habitutate using Ctrl-U to remove comment leader (this should help when I don't want it)
        opts = opts .. "o" --  insert comment leader on `o` and `O`
        opts = opts .. "r" --  insert comment leader on <Enter>
        opts = opts .. "j" --  remove comment leader when joining lines

        -- opt_local is for current file only
        vim.opt_local.formatoptions = opts
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "systemd",
    callback = function()
        vim.bo.commentstring = "# %s"
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = "filetypemods",
    pattern = "*.md",
    callback = function()
        -- FYI `vim.opt_local` (lua) == `setlocal` (vimscript)
        vim.wo.wrap = true -- window option so use BufWinEnter
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "svg",
    -- pattern = "xml,html,xsl,svg", -- todo add others?
    callback = function()
        vim.opt_local.wrap = true
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "lua",
    callback = function()
        -- TODO review nvim's bundled ftplugin/lua.vim and ftplugin/lua.lua and see if I wannna override anything in them
        -- vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "fish",
    callback = function()
        -- override commentstring to be # %s... was #%s (no space)
        --   I suspect there are gonna be times I hate this too ;)
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "sql",
    callback = function()
        vim.bo.commentstring = "-- %s" -- %s is original text
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "editorconfig",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

-- set commentstring for json files (i.e. coc-settings.json), obviously not all json readers can handle comments so be careful
vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "json",
    callback = function()
        vim.bo.commentstring = "// %s" -- %s is original text
    end,
})

-- yaml
vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "yaml",
    callback = function()
        -- FYI ftplugin/yaml.vim:28:  setlocal shiftwidth=2 softtabstop=2
        --     in nvim runtime
        -- actually I like 2...  I will fix formatters to use this
        -- vim.bo.shiftwidth = 4
        -- vim.bo.softtabstop = 4
    end
})

vim.api.nvim_create_autocmd("BufEnter", {
    group = "filetypemods",
    pattern = "*.gitconfig",
    callback = function()
        -- FYI this could be FileType autocmd if I wasn't fighting with coc's global format key maps
        vim.bo.commentstring = "# %s" -- %s is original tex

        -- setup to match indent that git config uses when using git config command...
        -- seems to match at least on mac
        vim.bo.expandtab = false -- Use tabs, not spaces
        vim.bo.tabstop = 4 -- Display width of a tab
        vim.bo.shiftwidth = 4 -- Indent size
        vim.bo.softtabstop = 4 -- Tab key behavior
    end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    -- otherwise conf.* are treated as conf files by default and there's no good coloring of that... so use ini
    pattern = "**/.grc/conf.*",
    callback = function()
        vim.bo.filetype = "ini"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "graphql",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

-- ~/.editrc
vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "editrc",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
        -- PRN do I want these here too:
        -- vim.bo.shiftwidth = 4
        -- vim.bo.tabstop = 4
    end,
})

-- ** help buffers
vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "help",
    callback = function()
        -- forward F12 to F1 ONLY in help buffer
        --   remap=true => so this calls keymap for lhs=<F1>
        --   buffer=true => only current (help) buffer
        vim.keymap.set('', '<F12>', '<F1>', { remap = true, buffer = true })
        -- equivalent:
        --   :map <buffer> <F11> <F1>
    end,
})

-- *** hcl
vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "hcl",
    callback = function()
        vim.bo.commentstring = "# %s"
    end,
})


-- *** fennel
function fennel_fmt()
    -- FYI could use marks '[ and '] if fnlfmt supported formatting line range in overall file
    -- for now gonna just format full buffer contents
    vim.cmd("%!fnlfmt -")
end

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "fennel",
    callback = function()
        vim.keymap.set("n", '=', function()
                -- unfortunately, fnlfmt doesn't support formatting a subset of lines (i.e. line range)...
                --   nor can I just pass lines standalone...
                --   so there's really no reason to wait for a motion...
                --   b/c its all or none for the full buffer contents...
                --   but, b/c the interface is gg=G (or otherwise) I am stuck waiting on motion

                vim.o.operatorfunc = "v:lua.fennel_fmt"
                return "g@"
            end,
            { expr = true, buffer = true }) -- buffer=true => only override for current buffer (fennel file type)
    end,
})



-- *** quit help on 'q' => see how I feel about this
vim.api.nvim_create_augroup("HelpQuitWithQ", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = "HelpQuitWithQ",
    pattern = "help",
    callback = function()
        vim.keymap.set("n", "q", ":q<CR>", { noremap = true, silent = true, buffer = true }) -- once is fine b/c this is buffer keymap, so FileType works (don't need BufWinEnter)
        -- PRN others?
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*.harmony",
    callback = function(...)
        -- FYI! with multiple windows (in separate tabs, not a split window alone in one tab) => same buffer  ... FileType event IS NOT APPROPRIATE for forced defaults
        -- *** use BufWinEnter if you have multiple windows pointed at the same buffer, on restore then this fires for each one (not just first like FileType event does)
        --  use pattern to limit, OR =>  if vim.bo.filetype == "harmony" then ... end
        vim.wo.wrap = true
        -- TODO port other FileType handlers above to use BufWinEnter instead (at least for window local options like wrap)
    end,
})
