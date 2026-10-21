function SwitchCopilot()
    local config = require("ask-openai.config")
    config.toggle_predictions()
end

-- *** switch copilot keymaps:
-- WEIRD, after iterm crash, or some other factor, F15 stopped working and I get S-F3 instead? using Ctrl-v ... WTH?
--   '<S-F3>' '<F15>'

vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<F18>', function() SwitchCopilot() end, { noremap = true, silent = true }) -- TODO remove?
--
-- <F41> == <C-S-F5> (Keyboard Maestro => use <C-S-...> for higher Function keys (menu only picks up to F20 otherwise)
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<F41>', function() require('ask-openai.config').toggle_fim_model() end,
    { noremap = true, silent = true })
-- <F42> = <C-S-F6>
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<F42>', function() require('ask-openai.config').toggle_rewrite_model() end,
    { noremap = true, silent = true })
-- <F43> = <C-S-F7>
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<F43>', function() require('ask-openai.config').toggle_agents_model() end,
    { noremap = true, silent = true })
--
-- <M-S-F5> (btw matches C-S-F5 used for model cycler for same frontend
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<M-S-F5>',
    function() require('ask-openai.config').cycle_fim_reasoning_level() end, { noremap = true, silent = true })
-- <M-S-F6>
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<M-S-F6>',
    function() require('ask-openai.config').cycle_rewrite_reasoning_level() end, { noremap = true, silent = true })
-- <M-S-F7>
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<M-S-F7>',
    function() require('ask-openai.config').cycle_agents_reasoning_level() end, { noremap = true, silent = true })
--
-- misc:
vim.keymap.set({ 'n', 'i', 'v', 'c' }, '<F17>', function() require('ask-openai.config').toggle_rag() end,
    { noremap = true, silent = true })

function CopilotsStatus()
    return require("ask-openai.status").get_lualine_components()
end

local ask_openai_plugin = {
    "g0t4/ask-openai.nvim",
    enabled = true,
    -- event = { "CmdlineEnter", "InsertEnter" }, -- my plugin handles when to load, right now it is selective so I don't really need this here
    dir = "~/repos/github/g0t4/ask-openai.nvim",

    config = function()
        require('ask-openai').setup()
    end,

    dependencies = {
        "nvim-lua/plenary.nvim",
        "bjornbytes/rxlua", -- tentative for predictions only (i.e. debounce)
    }
}

return {
    ask_openai_plugin,
    {
        "nvim-lua/plenary.nvim",
        config = function()
            -- nmap <leader>u <Plug>PlenaryTestFile
            -- think "u" in unit test (didn't have many leader keys left .. this works)
            vim.api.nvim_set_keymap("n", '<leader>u', "<Plug>PlenaryTestFile", { noremap = true, silent = true })
        end
    },
    {
        "bjornbytes/rxlua",
        config = function()
            -- rx.lua is in repo root (not in lua dir), so modify package path to support that
            -- CAREFUL with casing (RxLua is not gonna work if its rxlua, on a case sensitive fs... as all should be)
            local plugin_path = vim.fn.stdpath("data") .. "/lazy/rxlua/"
            package.path = package.path .. ";" .. plugin_path .. "?.lua"
        end
    },
}
