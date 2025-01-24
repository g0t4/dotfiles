-- TODO warn if werkspaces already loaded
-- FYI if issues with werkspace not having these options set... that can happen if this is registered after werkspaces are loaded

vim.cmd [[
    " SVG
    "autocmd FileType svg echo "SVG opened"
    autocmd FileType svg set wrap

    " markdown
    autocmd FileType md set wrap
]]

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

vim.api.nvim_create_autocmd("FileType", {
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
    pattern = "editorconfig",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

-- set commentstring for json files (i.e. coc-settings.json), obviously not all json readers can handle comments so be careful
vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
        vim.bo.commentstring = "// %s" -- %s is original text
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "graphql",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
    end,
})

-- ~/.editrc
vim.api.nvim_create_autocmd("FileType", {
    pattern = "editrc",
    callback = function()
        vim.bo.commentstring = "# %s" -- %s is original text
        -- PRN do I want these here too:
        -- vim.bo.shiftwidth = 4
        -- vim.bo.tabstop = 4
    end,
})
