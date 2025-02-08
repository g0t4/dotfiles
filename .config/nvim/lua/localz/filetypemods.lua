-- TODO warn if werkspaces already loaded
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
    },
})



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
        " - ",
        -- noteworthy:
        -- t = auto-wrap text using textwidth
        -- c = auto-wrap comments using textwidth
        "formatoptions:" .. tostring(vim.o.formatoptions)
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
end, { bang = true })

-- PRN review `autoindent`/`smartindent`/`cindent` and `smarttab` settings
--     filetype plugin indent on " this is controlling indent on new lines for now and seems fine so leave it as is
--     set backspace=indent,start,eol " allow backspacing over everything in insert mode, including indent from autoindent, eol thru start of insert


-- :h formatoptions
-- :h fo-table
--   o = insert comments on `o` and `O`
--      r = same for enter
--   autowrap lines
--      t = auto wrap regular text
--      c = auto wrap comments + insert comments leader too
--  j = remove comment leader when joining lines
--- q = gq formats comments
---

vim.api.nvim_create_augroup("filetypemods", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = "filetypemods",
    pattern = "markdown",
    callback = function()
        vim.opt_local.wrap = true
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
        -- print "my autocmd FileType"
        -- vim.bo.commentstring = "# %s" -- %s is original text

        -- wrapping related
        vim.cmd('set formatoptions-=c') -- disable wrapping comments on textwidth
        vim.cmd('set formatoptions-=t') -- disable wrapping regular text on textwidth
        vim.cmd('set formatoptions+=l') -- do not wrap in insert mode (when past textwidth columns) - was already default, just make explicit

        -- comment leaders:
        vim.cmd('set formatoptions+=o') -- insert comments on `o` and `O`
        vim.cmd('set formatoptions+=r') -- same for enter
        vim.cmd('set formatoptions+=j') -- remove comment leader when joining lines
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
