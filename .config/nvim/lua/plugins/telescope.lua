return {

    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
        },
        config = function()
            -- TODO lazy load on commands / keys (redefine keys using spec, same with commands if I want those to appear globally and be lazy loaded too)
            require('telescope').setup({
                defaults = {
                    layout_strategy = 'flex', -- based on width (kinda like this actually and it resizes with the window perfectly)
                    -- layout_strategy = 'vertical', -- default is horizontal (files+prompt left, preview right)
                    -- layout_strategy = 'horizontal', -- vertical = (preview top, files middle, prompt bottom) -- maximizes both list of files and preview content
                    layout_config = {
                        -- :help telescope.layout
                        horizontal = { width = 0.9 },
                        vertical = { width = 0.9 },
                    },
                },
                pickers = {
                    live_grep = {
                        layout_strategy = 'vertical',
                    },
                    find_files = {
                        theme = "dropdown", -- only style I found that has prompt at top w/ most relevant results right below it... all other prompt top layouts still show most relevant results at bottom which is odd to me
                        -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/pickers/layout_strategies.lua
                        -- layout_strategy = 'cursor', -- popup right where cursor is at? not sure I will always be expecting that... try and find out, FYI works w/ theme=dropdown

                        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                        -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
                        -- PRN use git_files and fallback to find_files: Falling back to find_files if git_files can't find a .git directory, wouldn't this be missing new files?

                        previewer = false, -- PRN make it more like vscode (focus on file names, not content, esp b/c I would do a grep files if I wanted to search by content)
                    },
                }
            })

            local builtin = require('telescope.builtin')

            vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Telescope find files' })
            vim.keymap.set('n', '<C-S-p>', builtin.commands, { desc = 'Telescope commands' }) -- PRN try this out, see if I like it better

            vim.keymap.set('n', '<leader>t', builtin.builtin, { desc = 'Telescope Builtin' }) -- list pickers, select one opens it (like if :Telescope<CR>), shows keymaps too

            -- FYI habituate Ctrl+V (open vertical split diff!)
            vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope live grep' }) -- proj search
            -- PRN ag? https://github.com/kelly-lin/telescope-ag  (extension  to telescope) => others https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions

            vim.keymap.set('n', '<leader>s', builtin.git_status, { desc = 'Telescope git status' })
        end,
    },

    {
        'catgoose/telescope-helpgrep.nvim',
        config = function()
            -- TODO lazy load considerations?
            require('telescope').load_extension('helpgrep') -- ensure shows in :Telescope list/completion

            -- PRN redirect F1 to this? or maybe F1 to grep help tags? .. what does F1 currently map to?
            vim.keymap.set('n', '<leader>h', ":Telescope helpgrep<CR>", { desc = 'Telescope helpgrep' }) -- not just help tags! (btw help tags already works via cmd line, dont need it here too)
        end,

    },

    {
        'xiyaowong/telescope-emoji.nvim',
        config = function()
            -- TODO lazy load considerations? load after telescope loads? or?
            -- TODO if telescope is loaded, does this show up under :Telescope e<TAB>?
            require("telescope").load_extension("emoji")

            vim.keymap.set('n', '<leader>te', ":Telescope emoji<CR>") -- use `<leader>t*` for less used pickers, may be slow due to overlap in <leader> keymaps but NBD
        end,
    }
    --
    -- use 'https://github.com/nvim-telescope/telescope-file-browser.nvim' -- prefer to use fuzzy find (not dir by dir)
    -- require("telescope").load_extension "file_browser"               -- this is why setting PWD matters when launching vim, at least for repo type projects, like w/ vscode
    -- vim.keymap.set('n', '<leader>br', ":Telescope file_browser<CR>") -- PRN shift+cmd+e would rock, can I get cmd to work in terminal w/ iTerm2?, I suspect iterm is always gonna snipe it
    --
    -- frecency on all pickers:
    -- use 'prochri/telescope-all-recent.nvim'
    --
    -- file frecency:
    --   :Telescope frecency workspace=CWD
    --      use workspace so files aren't system wide
    --      I don't like that the list only has previously opened files, I want all of them.. apparently it sounds like if you use an LSP that it can associate workspace files with it all in one go?
    -- use 'nvim-telescope/telescope-frecency.nvim'
    -- require('telescope').load_extension('frecency')
    --
    -- native fzf/fzy compiled extensions (for perf):
    --   https://github.com/nvim-telescope/telescope-fzf-native.nvim
    --   https://github.com/nvim-telescope/telescope-fzy-native.nvim
    --
    -- PRN review extensions: https://github.com/illia-shkroba/telescope-completion.nvim
    --  maybe... completions w/ telescope... I need to get completions going before I worry about this
    --  nvim-treesitter for telescope too?

}
