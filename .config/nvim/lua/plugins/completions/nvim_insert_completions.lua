-- what I care about:
--  complete require("foo.<TAB> to correct paths
--  F12 go to files
--  see my coc keymaps
--    gd/gr goto def, usages, etc
--
--  enter to accept, tab is reserved for copilot du jour plugin


-- PRN later try lua in nvim's LSP => focus specifically on API for symbols? is it superior to coc?
-- require('lspconfig').lua_ls.setup {
--   settings = {
--     Lua = {
--       runtime = { version = 'LuaJIT' },
--       diagnostics = { globals = { 'vim' } },
--       workspace = { library = vim.api.nvim_get_runtime_file("", true) },
--       telemetry = { enable = false },
--     },
--   },
-- }

