return {

    {
        'nvim-tree/nvim-web-devicons',
        lazy = true, -- load only when require'd
    },

    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<C-l>",     ":NvimTreeFindFile<CR>", mode = "n", noremap = true, silent = true },
            { "<C-S-l>",   ":NvimTreeFindFileToggle<CR>", mode = "n", noremap = true, silent = true },

            -- FYI cmd+shift+e => Esc+OQ iiterm settings => F2 (in term)
            { "<F2>",      ":NvimTreeFindFile<CR>",       mode = "n", noremap = true, silent = true },

            -- TODO move elsewhere when I find a spot, use alt instead of ctrl-w for moving between windows
            { "<M-right>", "<C-W><right>",                mode = "n", noremap = true, silent = true },
            { "<M-left>",  "<C-W><left>",                 mode = "n", noremap = true, silent = true },
            { "<M-up>",    "<C-W><up>",                   mode = "n", noremap = true, silent = true },
            { "<M-down>",  "<C-W><down>",                 mode = "n", noremap = true, silent = true },
        },
        config = function()
            require("nvim-tree").setup({
                renderer = {

                    -- show only folder name of root dir (not full path or even ~/ path):
                    root_folder_label = ":t", -- `:help filename-modifiers` for more choices, this is aka root_folder_modifier IIRC
                }
            })
            -- PRN telescope integration => actions menu (https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#creating-an-actions-menu-using-telescope)
            -- FYI `g?` shows help overlay with keymaps for actions
        end,
        init = function()
            -- must load early to disable netrw (else causes problems with nvim-tree)...
            --    FYI init runs before plugin is loaded, and seems to run soon enough that it works for ensuring netrw is disabled
            --    test of if this works is to do `nvim .` and see if it loads netrw or empty doc
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
        end,
    },

    -- {
    --     "nvim-neo-tree/neo-tree.nvim",
    --     branch = "v3.x",
    --     dependencies = {
    --         "nvim-lua/plenary.nvim",
    --         "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    --         "MunifTanjim/nui.nvim",
    --         -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    --     }
    -- },
}
