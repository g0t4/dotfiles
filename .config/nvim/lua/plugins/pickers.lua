return {

    {
        -- *** Command Palette Picker ***
        "mrjones2014/legendary.nvim",
        keys = {
            { '<C-S-p>', '<Cmd>Legendary<CR>', mode = 'n' },
            --
            -- notes:
            -- - think vscode cmd palette
            -- - can have both keymaps and commands
            --   - NOT a cmd line replacement, just like vscode cmd palette isn't a command line interface
            --   - again, builtin cmds are not included in the list by default
            --   - only cmds by default are for telescope itself
            -- - interesting way to notify users of deprecated config, I like it:
            --   - https://github.com/mrjones2014/legendary.nvim/blob/master/lua/legendary/deprecate.lua
            -- - uses telescope.nvim + dressing.nvim (via vim.ui.select)
            --
            -- pros:
            -- - I love searching by keymap type here, with this focused on a subset of all keymaps, it feels more helpful than a general doc search where there are many unrelated results
            --   i.e. <C-p> shows builtins and user defined keymaps!
            -- - search builtin commands (telescope didn't have this)
            -- - extensions for user defined commands
            -- - easy to mod discovery extension for lazy keys
            -- - fuzzy finder (also frecency though I don't know that I need that)
            -- - frecency too, TBD if I care about that
            --
            -- TODOs:
            -- - VERIFY why it is slow:
            --   - is it just first use, and b/c it has to discover (IIUC per buffer) all keymaps
            -- ! finish READing the full README for all the things I might want
            --   - https://github.com/mrjones2014/legendary.nvim
            -- - register all my user defined keymaps?
            --   - can I do that via which-key and not have to do anything extra?
            --     - make sure it uses rhs, I don't want to search descriptions alone
            --   - register my commands too?
            --   - register my lua funcs?
            -- - REVIEW DUPLICATE KEYMAPS (not a problem when its overriding a builtin)
            --   - esp helpful after I get all my userdefined keymaps registered
            -- - TODO maybe move to defining my keymaps with this tool too?
            --   - not sure I like the idea of "centralizing" keymaps though that might have benefits for overlapping keys in diff scenarios (i.e. PageUp)
            --
        },
        dependencies = {
            -- PRN do I need to mark these to load first? is it all working b/c I lazy load this (legendary)? could order be an issue with maybe nvim-tree?
            -- "stevearc/dressing.nvim",
            -- "nvim-telescope/telescope.nvim",
            -- "folke/which-key.nvim",
        },
        config = function()
            require('legendary').setup {
                include_builtin = true, -- show builtins (default true), i.e. zz (~323)
                include_legendary_cmds = true, -- legendary commands (default true) (12)
                extensions = {
                    -- keymap discovery extensions
                    --
                    -- TODO load user defined keymaps... is this not already an extension?! i.e. <PageUp>/<PageDown> and <leader> ... etc
                    --  TODO can I just use which-key extension and have it get those via that (or does it not pick up all of mine?)
                    --
                    -- FYI which_key isn't loading any either? what does it load? all keys which-key shows or some set that are added to which key itself? unsure
                    --    CAREFUL not to rebind the keys too
                    -- FYI   :h legendary-which-key.txt
                    -- which_key = true,
                    lazy_nvim = false, -- builtin requires desc set on lazy keys entries, and I want it to be rhs by default
                    my_lazy_nvim = true, -- my own lazy keys loader
                    --
                    -- FYI command palette builds list on first use (per buffer?), so that is why it has slight lag there and that also means you need to restart to rebuild the list
                    -- FYI ~/.cache/nvim/legendary/legendary.log shows discovery logs (if you use its own Log.debug it won't do multiparam nor multiline logs, so just use print(vim.inspect(foo))
                    --
                    -- troubleshoot why nvim_tree is also not working?!
                    --   - open nvim-tree
                    --   C-S-p before (nothing specific to nvim-tree
                    --   :lua require('legendary.extensions.nvim_tree')()
                    --   C-S-p now has 50+ extra entries (and they don't show in other windows so they are buffer specific)
                    -- nvim_tree = true, -- TODO this causes an error, that's why its not working (it's trying)! when first activate legendary in nvim-tree window
                    --     ERROR: "...l/share/nvim/lazy/nvim-tree.lua/lua/nvim-tree/keymap.lua:17: E565: Not allowed to change text or change window"
                    --     TODO is this rebinding the keys or?
                    --
                    --
                },
                -- ? does this go here or in extensions:
                -- which_key = {
                --     auto_register = true,
                -- },

            }
        end,
    },

    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            -- TODO popup.nvim?
        },
        cmd = { 'Telescope' }, -- lazy load on command used
        keys = {
            { '<C-p>',       ':Telescope find_files<CR>', mode = 'n' },
            { '<leader>t',   ':Telescope<CR>',            mode = 'n' }, -- list pickers, select one opens it (like if :Telescope<CR>), shows keymaps too
            -- { '<leader>s',   ':Telescope live_grep<CR>',  mode = 'n' }, -- keep top level w/o submapping collision so this is snappy fast
            { '<leader>gst', ':Telescope git_status<CR>', mode = 'n' }, -- like gst abbr/alias
        },
        config = function()
            local telescopeConfig = require('telescope.config')

            -- *** use rg
            -- Clone the default Telescope configuration
            -- local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
            -- -- FYI right now:        { "rg", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" }
            -- --    can just set these myself and make sure of it...
            -- -- I want to search in hidden/dot files.
            -- table.insert(vimgrep_arguments, "--hidden")
            -- table.insert(vimgrep_arguments, "--no-ignore") -- allow so gitignored files
            -- -- dirs to exclude now:
            -- table.insert(vimgrep_arguments, "--glob")
            -- table.insert(vimgrep_arguments, "!**/.git/*")
            -- table.insert(vimgrep_arguments, "--glob")
            -- table.insert(vimgrep_arguments, "!**/.venv/*")
            -- table.insert(vimgrep_arguments, "--glob")
            -- table.insert(vimgrep_arguments, "!**/node_modules/*")
            -- table.insert(vimgrep_arguments, "--glob")
            -- table.insert(vimgrep_arguments, "!**/iterm2env/*")
            -- print(vim.inspect(vimgrep_arguments))
            --
            -- *** use ag
            --    btw `ag -G lua` == `rg -g "*.lua"` -- YUCK... I shouldn't need *.lua to do lua... FUCK YUCK and then ALSO motherfucking "" or escaping *...no way
            local vimgrep_arguments = { 'ag', '--nocolor', '--nogroup', '--numbers', '--column', '--smart-case',
                -- FYI unrestricted = hidden + no ignores... nope... -u appears to ignore my --ignore... whereas -U doesn't....
                --   btw --hidden is needed to be able to search dotfiles (any file with leading dot, or dir)
                --   --ignore PATTERN ~= rg's --glob
                --   ag -U --ignore "iterm2env" -i "local"  # this works, doesn't show iterm2env paths
                --   ag -u --ignore "iterm2env" -i "local"  # this still shows iterm2env paths
                --   what is odd, is that -U is supposed to be about not consider .gitignore/.hgignore... and -u does that too plus .ignore files... so I don't know why the latter wouldn't also work for iterm2env filter?
                --
                '--hidden', '-U',
                '--ignore', '.venv/',
                '--ignore', 'iterm2env',
                '--ignore', '.git/',
                '--ignore', 'node_modules/',
                '--ignore', '__pycache__/',
            }
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
                            -- FYI testing popup key maps without leaving insert mode (and losing popup in some case): inoremap <C-c> <Cmd>verbose map \<Up\><CR>
                            --    also `:messages clear` ... but some of verbose map doesn't show up in :messages (todo is there some sort of <Cmd> caveat that loses some of the messages?)
                            ["<Esc>"] = require("telescope.actions").close,
                            -- CYCLE history of previous searches: (like command line history)
                            --  use Ctrl-Up/Down so arrows can move through results of current search
                            ["<C-Up>"] = require("telescope.actions").cycle_history_prev,
                            ["<C-Down>"] = require("telescope.actions").cycle_history_next,
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
                },
                extensions = {
                    live_grep_args = {
                        -- FYI ok to leave on auto_quoting... otherwise I always have to quote when I want multiple words in search string with spaces
                        --    even with it on... I can mostly think about the prompt as command line args... and it only works by magic in special cases for me and I don't think those will throw me off as I can always use "" if I am confused
                        -- auto_quoting = false,
                        -- TODO! fuzzy refine?
                        -- mappings?
                        --   ["<C-k>"] = lga_actions.quote_prompt(),
                        --   ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                        -- -- freeze the current list and start a fuzzy search in the frozen list
                        --   ["<C-space>"] = actions.to_fuzzy_refine,
                        --
                        --   grep_word_under_cursor  -- avail via live_grep_args too
                        --   grep_word_under_cursor_current_buffer
                        --   grep_visual_selection
                        --      IIRC in code, telescope's builtin has this too I just never mapped visual mode keys
                        --   grep_word_visual_selection_current_buffer
                        layout_strategy = 'vertical',
                    }
                }
            })
            -- FYI this complements <leader>s which opens live_grep with empty search query
            vim.keymap.set('n', '<leader>w', function()
                require('telescope.builtin').live_grep({
                    default_text = vim.fn.expand('<cword>')
                })
            end, { desc = "Live grep, starting with word under cursor" })
        end,
    },
    {
        -- live_grep + pass args!
        --   thus, can pass params to filter file path too (ag's -G, rg's -r glob)
        --   TLDR removes the "--" in the upstream live_grep (lolz)
        --      https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/__files.lua#L172
        --             return flatten { args, "--", prompt, search_list }
        --      https://github.com/nvim-telescope/telescope-live-grep-args.nvim/blob/master/lua/telescope/_extensions/live_grep_args.lua#L58
        --             return
        --   YUP 100% this is goal (so you can pass args too)
        --      here is a PR that inspired live-grep-args ext!
        --      https://github.com/nvim-telescope/telescope.nvim/pull/670
        'nvim-telescope/telescope-live-grep-args.nvim',
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
        config = function()
            require('telescope').load_extension('live_grep_args')
            vim.keymap.set('n', '<leader>s', function()
                require("telescope").extensions.live_grep_args.live_grep_args()
            end, { desc = "Live grep with custom args or empty search query" })
            --
            -- UMM... to_fuzzy_refine is not in the codebase?!
            -- vim.keymap.set('n', '<C-space>', function()
            --     require("telescope-live-grep-args.actions").to_fuzzy_refine()
            -- end, { desc = "freeze test" })
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
