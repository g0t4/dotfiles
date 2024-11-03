local M = {}
M.theme = function()
    -- KEEP existing theme from onedarkpro for lualine status bar components... then make mods

    -- have to get the theme by entire file path b/c lualine shadows this one
    local lazycfg = require("lazy.core.config")
    local odp_plugin_install_dir = lazycfg.plugins["onedarkpro.nvim"].dir
    if not odp_plugin_install_dir then
        -- just in case I change config and mess up ordering or don't have plugins yet all installed, add some graceful death
        vim.notify("onedarkpro.nvim plugin not found, cannot modify its lualine theme", vim.log.levels.ERROR)
        return
    end
    local theme = dofile(odp_plugin_install_dir .. "/lua/lualine/themes/onedark.lua")

    -- when two windows stacked, and bottom active, the top statusline should clearly split the two, by default it appears transparent which makes it confusing to see where top ends and bottom begins
    theme.inactive = {
        a = { bg = "#22262d" },
        b = { bg = "#22262d" },
        c = { bg = "#22262d" },
    }

    return theme
end
return M
