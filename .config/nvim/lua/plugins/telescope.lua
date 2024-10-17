local telescopeConfig = require('telescope.config')

-- Clone the default Telescope configuration
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
-- I want to search in hidden/dot files.
table.insert(vimgrep_arguments, "--hidden")
-- I don't want to search in the `.git` directory.
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")

return {

    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            -- TODO popup.nvim?
        },
        cmd = { 'Telescope' }, -- lazy load on command used
        keys = {
            { '<C-p>',     ':Telescope find_files<CR>', mode = 'n' },
            { '<C-S-p>',   ':Telescope commands<CR>',   mode = 'n' }, -- PRN try this out, see if I like it better
            { '<leader>t', ':Telescope<CR>',            mode = 'n' }, -- list pickers, select one opens it (like if :Telescope<CR>), shows keymaps too
            { '<leader>g', ':Telescope live_grep<CR>',  mode = 'n' }, -- proj search
            { '<leader>s', ':Telescope git_status<CR>', mode = 'n' },
        },
        config = function()
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
                    vimgrep_arguments = vimgrep_arguments,
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
        end,
    },

    {
        'prochri/telescope-all-recent.nvim',
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "kkharji/sqlite.lua",
            -- optional, if using telescope for vim.ui.select
            -- "stevearc/dressing.nvim"
            -- TODO try this optional dep (stevearc)
        },
        config = function()
            require'telescope-all-recent'.setup({
                -- FYI yes I know I should be using `opts` esp if not overriding any settings, still leaving this as its more obvious that:
                -- FYI if opts not set and this config is not setup, it won't load this ext (file list is all sorted by original order)
                -- FTR i don't likely need this on EVERY PICKER, probably just the file pickers... I didn't use the builtin oldfiles picker b/c it spanned all files ever opened, when I want it to be "per project" (root dir, like in vscode)
                -- ALSO, this must come first if wanting to map keys to require("telescope").builtins.xyz() b/c it monkey patches the builtins
            })
        end,
    },

    {
        'catgoose/telescope-helpgrep.nvim',
        dependencies = {
            { 'nvim-telescope/telescope.nvim' },
        },
        cmd = { 'Telescope helpgrep' }, -- lazy load on command used
        keys = {
            { '<leader>h', ':Telescope helpgrep<CR>', mode = 'n' },
        },
        config = function()
            require('telescope').load_extension('helpgrep') -- ensure shows in :Telescope list/completion
        end,

    },

    {
        'xiyaowong/telescope-emoji.nvim',
        dependencies = {
            { 'nvim-telescope/telescope.nvim' },
        },
        cmd = { 'Telescope emoji' }, -- lazy load on command used
        keys = {
            { '<leader>te', ':Telescope emoji<CR>', mode = 'n' },
            -- use `<leader>t*` for less used pickers, may be slow due to overlap in <leader> keymaps but NBD
        },
        config = function()
            require("telescope").load_extension("emoji")
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
