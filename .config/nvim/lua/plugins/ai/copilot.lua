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
