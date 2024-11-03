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
        -- todo use 22262d if I got back to original bg color 282c34 from onedarkpro...
        -- using 282c34 with my new darker ODP bg 22262d
        a = { bg = "#282c34" },
        b = { bg = "#282c34" },
        c = { bg = "#282c34" },
    }

    return theme

    -- NOTES when researching default color theme
    --   FYI `theme =` is from lualine's setup() function (I retired these notes here)
    --
    -- *** lualine's is a grey theme (not green/blue in normal/insert mode)
    -- theme = require("lualine.themes.onedark"), -- due to rtp ordering this way lualine's wins
    -- theme = dofile("/Users/wes/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes/onedark.lua"),
    -- lua print(vim.inspect(dofile("/Users/wes/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes/onedark.lua")))
    --
    -- *** onedarkpro's is the green/blue theme I am used to (wins b/c of plugin ordering and priority)
    -- theme = dofile("/Users/wes/.local/share/nvim/lazy/onedarkpro.nvim/lua/lualine/themes/onedark.lua"),
    -- theme = dofile(require("lazy.core.config").plugins["onedarkpro.nvim"].dir .. "/lua/lualine/themes/onedark.lua"),
    -- FYI find path to plugin dir (so can dofile() on it):
    --   :lua print(vim.inspect(require("lazy.core.config").plugins))
    --
end

return M
