local M = {}
M.theme = function()
    -- have to get the theme by entire file path b/c lualine shadows this one
    local lazycfg = require("lazy.core.config")
    local odp_plugin_install_dir = lazycfg.plugins["onedarkpro.nvim"].dir
    if not odp_plugin_install_dir then
        -- just in case I change config and mess up ordering or don't have plugins yet all installed, add some graceful death
        vim.notify("onedarkpro.nvim plugin not found, cannot modify its lualine theme", vim.log.levels.ERROR)
        return
    end
    local theme = dofile(odp_plugin_install_dir .. "/lua/lualine/themes/onedark.lua")

    theme.inactive = {
        a = { fg = "#727169", bg = "#16161D", gui = "bold" },
        b = { fg = "#727169", bg = "#16161D" },
        c = { fg = "#727169", bg = "#16161D" },
    }

    return theme

    -- -- GOALs:
    -- -- 1. Make inactive windows have a different bg color, b/c when top window is inactive (bottom active), the default is transparent bg which is not obvious then which window it is a part of IMO
    -- --
    -- -- FYI this file originally from https://www.reddit.com/r/neovim/comments/s4ud1d/make_lualine_background_transparent/
    -- --
    -- -- FYI here is onedark's base theme!
    -- --    ~/.local/share/nvim/lazy/onedarkpro.nvim/lua/lualine/themes/onedark.lua
    -- --    WAIT I think I should import and modify this instead
    -- local colors = {
    --     darkgray = "#16161d",
    --     gray = "#727169",
    --     innerbg = nil,
    --     outerbg = "#16161D",
    --     normal = "#7e9cd8",
    --     insert = "#98bb6c",
    --     visual = "#ffa066",
    --     replace = "#e46876",
    --     command = "#e6c384",
    -- }
    -- return {
    --     inactive = {
    --         a = { fg = colors.gray, bg = colors.outerbg, gui = "bold" },
    --         b = { fg = colors.gray, bg = colors.outerbg },
    --         c = { fg = colors.gray, bg = colors.innerbg },
    --     },
    --     visual = {
    --         a = { fg = colors.darkgray, bg = colors.visual, gui = "bold" },
    --         b = { fg = colors.gray, bg = colors.outerbg },
    --         c = { fg = colors.gray, bg = colors.innerbg },
    --     },
    --     replace = {
    --         a = { fg = colors.darkgray, bg = colors.replace, gui = "bold" },
    --         b = { fg = colors.gray, bg = colors.outerbg },
    --         c = { fg = colors.gray, bg = colors.innerbg },
    --     },
    --     normal = {
    --         a = { fg = colors.darkgray, bg = colors.normal, gui = "bold" },
    --         b = { fg = colors.gray, bg = colors.outerbg },
    --         c = { fg = colors.gray, bg = colors.innerbg },
    --     },
    --     insert = {
    --         a = { fg = colors.darkgray, bg = colors.insert, gui = "bold" },
    --         b = { fg = colors.gray, bg = colors.outerbg },
    --         c = { fg = colors.gray, bg = colors.innerbg },
    --     },
    --     command = {
    --         a = { fg = colors.darkgray, bg = colors.command, gui = "bold" },
    --         b = { fg = colors.gray, bg = colors.outerbg },
    --         c = { fg = colors.gray, bg = colors.innerbg },
    --     },
    -- }
end
return M
