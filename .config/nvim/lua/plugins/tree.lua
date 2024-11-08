function NvimTreeFindFileOrClose()
    if vim.bo.filetype == "NvimTree" then
        -- <C-l> should close tree view if its open and current window (that way I can <C-l> to quickly open and close it)
        vim.cmd("NvimTreeClose")
    else
        -- BUT, <C-l> always opens to current file if not in tree view, that way <C-l> doesn't toggle close/open when not in tree view
        vim.cmd("NvimTreeFindFile")
    end
end

function testUI()
    vim.ui.input({ prompt = "Rename File: " }, function(input)
        vim.notify(input)
    end)
end

return {

    -- {
    --     "MunifTanjim/nui.nvim",
    --     config = function()
    --         local Input = require("nui.input")
    --         local Select = require("nui.menu")
    --         -- Override vim.ui.input
    --         vim.ui.input = function(opts, on_confirm)
    --             local input_popup = Input({
    --                 position = "50%",
    --                 size = { width = 40 },
    --                 border = {
    --                     style = "rounded",
    --                     text = { top = opts.prompt or "Input" },
    --                 },
    --             }, {
    --                 on_submit = function(value)
    --                     on_confirm(value)
    --                 end,
    --             })
    --             input_popup:mount()
    --         end
    --         -- Override vim.ui.select
    --         vim.ui.select = function(items, opts, on_choice)
    --             local menu_items = {}
    --             for _, item in ipairs(items) do
    --                 table.insert(menu_items, Select.item(item))
    --             end
    --             local select_popup = Select({
    --                 position = "50%",
    --                 size = { width = 40, height = 10 },
    --                 border = {
    --                     style = "rounded",
    --                     text = { top = opts.prompt or "Select an option" },
    --                 },
    --                 win_options = { winblend = 10 },
    --             }, {
    --                 lines = menu_items,
    --                 on_submit = function(item)
    --                     on_choice(item.text)
    --                 end,
    --             })
    --             select_popup:mount()
    --         end
    --     end,
    -- },

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
            { "<C-l>",     ":lua NvimTreeFindFileOrClose()<CR>", mode = "n", noremap = true, silent = true },
            { "<C-S-l>",   ":NvimTreeFindFileToggle<CR>",        mode = "n", noremap = true, silent = true },

            -- TODO move elsewhere when I find a spot, use alt instead of ctrl-w for moving between windows
            { "<M-right>", "<C-W><right>",                mode = "n", noremap = true, silent = true },
            { "<M-left>",  "<C-W><left>",                 mode = "n", noremap = true, silent = true },
            { "<M-up>",    "<C-W><up>",                   mode = "n", noremap = true, silent = true },
            { "<M-down>",  "<C-W><down>",                 mode = "n", noremap = true, silent = true },
        },
        config = function()
            require("nvim-tree").setup({
                -- seems to work OOB?
                update_focused_file = {
                    enable = true, -- update the focused file on `BufEnter`, so when I switch files (i.e. w/ telescope) it shows the latest in the tree view to avoid confusing me (like vscode)
                    -- THAT SAID, maybe I really shouldn't rely on tree view to show file name, gotta habituate using statusline for that?
                    -- if setting this is a burden for perf then I should get rid of it, IIAC this has no impact if nvim-tree is closed?

                    -- FYI, I am very particular about the current root dir (think workspace/project)
                    -- update_root.enable -- I don't wanna update root dir if I open a file outside the current root dir, I also don't expect that to show in nvim-tree
                },
                renderer = {

                    -- show only folder name of root dir (not full path or even ~/ path):
                    root_folder_label = ":t", -- `:help filename-modifiers` for more choices, this is aka root_folder_modifier IIRC
                },
                filters = {
                    -- -- btw true/exclude == filtered out, false/include == shown
                    -- dotfiles = false, -- false = show dotfiles, false (default)
                    custom = { -- hidden:
                        "^\\.git",
                    },
                    -- exclude = { -- show: (don't filter out)
                    -- }
                },
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
