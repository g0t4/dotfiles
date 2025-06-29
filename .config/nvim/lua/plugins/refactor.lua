return {

    {
        -- TODO how to pick between this and Coc and other refactoring plugins?
        "ThePrimeagen/refactoring.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        lazy = false,
        config = function()
            require("refactoring").setup({

                --
                -- TODO try these print debug statements and cleanup... sounds good to me
                -- print_var_statements = {
                --     -- add a custom print var statement for cpp
                --     cpp = {
                --         'printf("a custom statement %%s %s", %s)'
                --     }
                -- }
                --
                -- extract_var_statements = {
                --     go = "%s := %s // poggers"
                -- }
                --
                -- TODO enable prompt for placeholders in some cases (w/o this it just inserts placeholder text w/o stepping to it IIUC):
                -- https://github.com/ThePrimeagen/refactoring.nvim#configuration-for-type-prompt-operations
                -- prompt_func_return_type = {
                --     go = true,
                --     cpp = true,
                --     c = true,
                --     java = true,
                -- },
                -- -- prompt for function parameters
                -- prompt_func_param_type = {
                --     go = true,
                --     cpp = true,
                --     c = true,
                --     java = true,
                -- },
                --

            })

            -- TODO try print feature:
            -- -- You can also use below = true here to to change the position of the printf
            -- -- statement (or set two remaps for either one). This remap must be made in normal mode.
            -- -- vim.keymap.set("n", "<leader>rp", function() require('refactoring').debug.printf({ below = false }) end)
            -- -- Print var
            vim.keymap.set({ "x", "n" }, "<leader>rp", function() require('refactoring').debug.print_var() end)
            vim.keymap.set("n", "<leader>rpc", function() require('refactoring').debug.cleanup({}) end)

            -- easiest to trigger...
            -- * refactor menu
            -- require("telescope").load_extension("refactoring") -- ONLY if using telescope picker
            vim.keymap.set(
                { "n", "x" },
                "<leader>rr",
                -- diff selectors:
                -- TODO can I merge prefer_ex_cmd with telescope picker?
                -- function() require('telescope').extensions.refactoring.refactors() end -- telescope picker
                -- function() require('refactoring').select_refactor() end -- vim.ui.input picker

                -- I like this style! i.e. to see preview when extracting a variable, while typing new name!
                --   should show if extracting from two spots too
                function() require('refactoring').select_refactor({ prefer_ex_cmd = true }) end -- show preview of changes
            )

            -- TODO what needs x (visual) vs just [n]ormal mode?
            -- get list of refactorings:
            --    =require("refactoring").get_refactors()
            --
            -- FYI Lua API - https://github.com/ThePrimeagen/refactoring.nvim#lua-api-
            --
            -- * inline
            vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var<Cr>") -- no added params, hence <Cr> to submit
            vim.keymap.set({ "n", "x" }, "<leader>rif", ":Refactor inline_func<Cr>") -- no added params
            -- alternative via Lua API:
            -- vim.keymap.set({ "n", "x" }, "<leader>ri", function() return require('refactoring').refactor('Inline Variable') end, { expr = true })
            -- vim.keymap.set({ "n", "x" }, "<leader>rif", function() return require('refactoring').refactor('Inline Function') end, { expr = true })
            --
            -- * extract
            vim.keymap.set({ "n", "x" }, "<leader>re", ":Refactor extract_var<Cr>i") -- FYI `i` on end is to put input box into insert mode (starts in normal mode)... so I can immediately type the name (w/o `i` myself)
            vim.keymap.set({ "n", "x" }, "<leader>ref", function() return require('refactoring').refactor('Extract Function') end, { expr = true })
            vim.keymap.set({ "n", "x" }, "<leader>retf", ":Refactor extract_to_file<Cr>") -- PERHAPs use refactor menu for this one?
            vim.keymap.set({ "n", "x" }, "<leader>reb", ":Refactor extract_block<Cr>")
            vim.keymap.set({ "n", "x" }, "<leader>rebtf", ":Refactor extract_block_to_file<Cr>") -- PERHAPS use refactor menu for this one?
        end,
    },

}
