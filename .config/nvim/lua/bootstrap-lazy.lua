local nvim = require("non-plugins.nvim")

if nvim.is_noplugin() then
    if nvim.is_running_plenary_test_harness() then
        -- don't log extra messages when testing
        return
    end
    print("skipping lazy.nvim b/c --noplugin was passed to nvim command")
    return
end

-- benefits/differences:
-- stellar panel overview of plugins
--  aside rom lazy loading
--  auto install depencies (dont have to PackerSync)
--      SO NICE, no more :wq, :PackerSync, :q, nvim to test a plugin change (also no ordering issues w/ run on a new plugin that caused a failure b/c wasn't yet installed on next restart to install)
--      TLDR I focus on spec and it handles the rest... what now how
--  detects config changes, says reloading... but some things maybe dont reload like keys? TBD
--  `dev` override to use local dep for testing while leave original spec as is
--  lazy load on: keys, cmds, filetypes, events, ... super flexible
--     priorities too
-- forces nice organization of plugins
-- shows startup reasons (to aide lazy loading) and timing (profile)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
    -- FYI here is the core config logic: https://github.com/folke/lazy.nvim/blob/main/lua/lazy/core/config.lua#L179


    spec = {

        -- INSTEAD OF AUTO LOAD ... I want require calls below so I can easily comment out spec files to troubleshoot across plugins
        -- { import = "plugins" },
        -- ALSO, use enabled to one off disable plugin(s)... esp for permenant disablement...
        -- SO, comment out when want to say disable everything and troubleshoot:
        -- !!! ADD NEW PLUGINS SPECS HERE
        require("plugins.0-tangerine"),
        require("plugins.code"),
        require("plugins.colors"),
        require("plugins.comments"),
        require("plugins.completions"),
        require("plugins.copilot"),
        require("plugins.debug-dap"),
        require("plugins.debug-vimspector"),
        require("plugins.filetypeplugins"),
        require("plugins.ft-markdown"),
        require("plugins.learning"),
        require("plugins.lualine"),
        require("plugins.misc"),
        require("plugins.terminals"),
        require("plugins.pickers"),
        require("plugins.refactor"),
        require("plugins.tree"),
        require("plugins.treesitter"),
        require("plugins.wilder"),
        require("plugins.g0t4"),
        -- YES, I need to manually add new entries here.. that is fine

    },

    -- colorscheme that will be used when installing plugins
    install = { colorscheme = { "habamax" } },

    -- automatically check for plugin updates
    checker = {
        enabled = true,
        notify = false, -- don't block startup to tell me this
    },

    change_detection = {
        enabled = true,
        notify = false
    }
})
