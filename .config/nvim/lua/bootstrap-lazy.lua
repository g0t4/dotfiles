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

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
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

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
