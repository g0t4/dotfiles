local M = {}
-- ? is it a problem to call this module "nvim"? perhaps move it into a nested dir at least so it's "namespaced"

function M.is_noplugin()
    return vim.tbl_contains(vim.v.argv, '--noplugin')
    -- return vim.iter(vim.v.argv):any(function(arg) return arg == "--noplugin" end)
end

function M.is_headless()
    -- i.e. why I don't want to run during headless mode, plenary tests uses it:
    --   <Plug>PlenaryTestFile => test harness:
    --     https://github.com/nvim-lua/plenary.nvim/blob/857c5ac/lua/plenary/test_harness.lua#L84-L87
    --   vim.v.argv during plneary test run:
    --    { "/opt/homebrew/Cellar/neovim/0.11.0/bin/nvim", "--headless", "-c",
    --      "set rtp+=.,/Users/wesdemos/.local/share/nvim/lazy/plenary.nvim | runtime plugin/plenary.vim",
    --      "--noplugin", "-c",
    --      'lua require("plenary.busted").run("/Users/wesdemos/repos/github/g0t4/zeta.nvim/lua/zeta/diff/histogram.tests.lua")' }
    --
    --     FYI if I need to detect plenary only, look for "plenary.busted" in vim.v.argv
    return vim.tbl_contains(vim.v.argv, '--headless')
end

function M.is_running_plenary_test_harness()
    return vim.iter(vim.v.argv)
        :any(function(arg)
            return arg:find("plenary%.busted") ~= nil
        end)
end

return M
