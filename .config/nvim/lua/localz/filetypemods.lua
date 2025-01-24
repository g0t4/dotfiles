vim.cmd [[

    " SVG
    "autocmd FileType svg echo "SVG opened"
    autocmd FileType svg set wrap




    " markdown
    autocmd FileType md set wrap


]]


-- TODO review formatoptions
--   o = insert comments on `o` and `O`
--      r = same for enter
--   autowrap lines
--      t = auto wrap regular text
--      c = auto wrap comments + insert comments leader too
--  j = remove comment leader when joining lines
--- q = gq formats comments
---
-- REMOVE c for wrap comments:

-- TODO review indent options
--   o = insert vim.o.comments on `o` and `O`
--
-- TODO address any issues w/ custom lua settings I have scattered elsewhere, gather them here?

vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
        -- TODO is this not firing for focused window/buffer after werkspace reloads last session?

        -- vim.bo.commentstring = "# %s" -- %s is original text

        -- BTW if I put formatoptions changes in ftplugin/lua.lua ... it seems to be overriden or not applied, but it works here:
        --   so for now, dont use ftplugin/lua.lua, use this autocmd

        -- wrapping related
        vim.cmd('set formatoptions-=c') -- disable wrapping comments on textwidth
        vim.cmd('set formatoptions-=t') -- disable wrapping regular text on textwidth
        vim.cmd('set formatoptions+=l') -- do not wrap in insert mode (when past textwidth columns) - was already default, just make explicit

        -- comment leaders:
        vim.cmd('set formatoptions+=o') -- insert comments on `o` and `O`
        vim.cmd('set formatoptions+=r') -- same for enter
        vim.cmd('set formatoptions+=j') -- remove comment leader when joining lines

        -- TODO any others I wanna explicitly set?

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
