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
            local telescopeConfig = require('telescope.config')

            -- Clone the default Telescope configuration
            local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
            -- I want to search in hidden/dot files.
            table.insert(vimgrep_arguments, "--hidden")
            table.insert(vimgrep_arguments, "--no-ignore") -- allow so gitignored files
            -- dirs to exclude now:
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.git/*")
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.venv/*")
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/node_modules/*")
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/iterm2env/*")
            -- TODO any better ideas on how to allow some of ignored files minus the obnoxious ones? or can I use an ignore file and pass it here and below in find_files?
            -- TODO sync the ignored/included with nvim-tree plugin too?

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
                    mappings = {
                        i = {
                            -- close on esc, otherwise have to double press esc to close (also this prevents me from going to normal mode which I don't want in this picker - at least not yet)
                            -- FYI registers for the popup/float window only (confirmed by disabling this and using Esc into normal mode to check with :verbose nmap <Esc>)
                            ["<Esc>"] = require("telescope.actions").close,
                        },

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

                        find_command = { "rg", "--files", "--no-ignore", "--hidden", "--glob", "!**/.git/*", "--glob", "!**/.venv/*", "--glob", "!**/node_modules/*", "--glob", "!**/iterm2env/*" },
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
            require 'telescope-all-recent'.setup({
                default = {
                    -- sorting = 'recent',  -- default is 'recent' (then there are overrides per picker)
                },
                -- FYI see current settings:
                --    lua print(vim.inspect(require('telescope-all-recent').config()))
                pickers = {
                    -- I prefer recent files to be at top, and then fuzzy find thereafter, frecency feels much less relevant IMO and IIUC vscode does it that way too, I always wanna jump to last used files, not most used
                    -- why? b/c I prefer not to type anything if possible... that said maybe I should use jump list for that? I dunno...
                    -- would be interesting to do sorting on recent and flip to frecency once I start typing chars? so nothing typed == recent, chars typed == frecency?
                    find_files = {
                        sorting = 'recent',
                    },
                    git_files = {
                        sorting = 'recent',
                    },
                },
                -- UMM ...  looks like ":Telescope builtins" is partially broken, in the Grep Preview pane, it doesn't scroll to the builtin's keymap section, might be stuck on the top of the file or?
                --   confirmed this isn't broken when I disable this plugin, can I disable just this one picker? as I don't really need frecency on list of builtins...
                --   fix this if and when it really annoys me... that said I wanted to lookup a key for these!
                --
                --   Alternative => just for files which is probably fine => https://github.com/nvim-telescope/telescope-frecency.nvim
                --
                -- FYI yes I know I should be using `opts` esp if not overriding any settings, still leaving this as its more obvious that:
                -- FYI if opts not set and this config is not setup, it won't load this ext (file list is all sorted by original order)
                -- FTR i don't likely need this on EVERY PICKER, probably just the file pickers... I didn't use the builtin oldfiles picker b/c it spanned all files ever opened, when I want it to be "per project" (root dir, like in vscode)
                -- ALSO, this must come first if wanting to map keys to require("telescope").builtins.xyz() b/c it monkey patches the builtins
                -- TODO do I want to customize algorithm for recent vs frequent? only time will tell, just a reminder to do that if it annoys me enough
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
