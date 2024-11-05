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
            require("refactoring").setup()

            -- not a huge fan of this menu style but it works, would rather have some shortcut keys to pick which submenu (an align them with the below specific keymaps so <leader>rr <letter>
            -- prompt for a refactor to apply when the remap is triggered
            vim.keymap.set(
                { "n", "x" },
                "<leader>rr",
                function() require('refactoring').select_refactor() end
            )
            -- Note that not all refactor support both normal and visual mode

            -- FYI right now coc maps: <leader>r,rn,re though I am not sure any extensions support these for any laguages I am using

            vim.keymap.set("x", "<leader>rx", ":Refactor extract ")
            vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")
            vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

            vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")
            vim.keymap.set("n", "<leader>rI", ":Refactor inline_func")
            vim.keymap.set("n", "<leader>rb", ":Refactor extract_block")
            vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")
        end,
    },

}
