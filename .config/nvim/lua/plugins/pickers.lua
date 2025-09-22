local function telescope_resume(num)
    return {
        '<leader>tr' .. num,
        function()
            require('telescope.builtin').resume({ cache_index = num })
        end,
        mode = 'n',
    }
end

local resume_keys = vim.iter({ 1, 2, 3, 4, 5, 6, 7, 8, 9 })
    :map(function(num)
        return telescope_resume(num)
    end)
    :totable()

local telescope_keys =
{
    { '<C-p>',       ':Telescope find_files<CR>', mode = 'n' },
    { '<leader>t',   ':Telescope<CR>',            mode = 'n' }, -- list pickers, select one opens it (like if :Telescope<CR>), shows keymaps too
    -- PRN if tr is cumbersome, find a new top level keymap like <leader>r (but I use that for refactoring)
    { '<leader>tr',  ':Telescope resume<CR>',     mode = 'n' },
    { '<leader>tp',  ':Telescope pickers<CR>',    mode = 'n' }, -- *** LIST and select a cached picker session, instead of guessing the number and using <leader>tr#

    -- TODO! move all telescope less used pickers to <leader>t* to free up other <leader> lhs
    { '<leader>tb',  ':Telescope buffers<CR>',    mode = 'n' },
    { '<leader>tk',  ':Telescope keymaps<CR>',    mode = 'n' },
    -- { '<leader>s',   ':Telescope live_grep<CR>',  mode = 'n' }, -- keep top level w/o submapping collision so this is snappy fast

    -- FYI <leader>tg => will open picker of pickers and g will select the git ones... DO NOT MAP OVER THAT! .. probably best way to pick from multiple git pickers is to not have each one keymapped
    -- * habituate <SPACE>gst ... I like it... so I don't have to exit nvim to check gst (or open terminal inside)
    { '<leader>gst', ':Telescope git_status<CR>', mode = 'n' }, -- like gst abbr/alias
    unpack(resume_keys), -- FYI keep this at end of this table ctor for telescope_keys... otherwise, it will effectively only unpack the first item in resume_keys, use vim.list_extend to reliably merge the lists
    -- DO NOT PUT ANY keymaps here after the unpack
}
-- vim.list_extend(telescope_keys, resume_keymaps)

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
        'nvim-telescope/telescope-smart-history.nvim',
        config = function()
            require('telescope').load_extension('smart_history')
        end,
    },
    --
    -- {
    --     -- TODO try telescope for selection lists (i.e. code actions)
    --     'nvim-telescope/telescope-ui-select.nvim',
    --     config = function()
    --         require('telescope').load_extension('ui-select')
    --     end
    -- },

    {
        'nvim-telescope/telescope.nvim',
        -- tag = '0.1.8',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            -- TODO popup.nvim?
        },
        cmd = { 'Telescope' }, -- lazy load on command used
        keys = telescope_keys,
        config = function()
            local telescopeConfig = require('telescope.config')

            local function rg_search()
                -- FYI use ripgreprc for universal overrides
                local args = { "rg", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column",
                    -- consider either --smart-case or --ignore-case by default? I can add an arg to override either and it will take precedence since its at the end of the args list IIUC how livegrep args + rg worsk
                    "--smart-case"

                    -- ripgreprc has these
                    -- "--hidden", -- for dotfiles/dirs
                    -- "--glob", "!.git", -- --hidden allows .git dir searching, so block it

                    -- UNUSED:
                    -- "--no-ignore" -- allows gitignored files
                    -- FYI use these if you enable -U by default, which is probably not a good idea...
                    -- "--glob", "!.venv/", -- --hidden doesn't match .venv
                    -- "--glob", "!node_modules/", -- --hidden doesn't match node_modules
                    -- "--glob", "!iterm2env/", -- --hidden doesn't match iterm2env
                }
                return args

                -- * NOTES:
                -- OOB telescope uses ripgrep, can see defaults:
                -- local args = { unpack(telescopeConfig.values.vimgrep_arguments) }
                -- defaults: { "rg", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" }

                -- should I check if env var is set since I depend on it here?
                --   if I launch nvim outside of a shell, I wouldn't have the env var then (necessarily)
                --   just tested wes-dispatcher.app (automator) for Open in Neovim... has en var set (uses fish shell script to open those nvim instances)
                --
            end


            ---@diagnostic disable-next-line: unused-function, unused-local
            local function ag_search()
                local ag_vimgrep_args = { 'ag', '--nocolor', '--nogroup', '--numbers', '--column', '--smart-case',
                    --   btw --hidden is needed to be able to search dotfiles (any file with leading dot, or dir)
                    '--hidden',
                    '--ignore', '.venv/',
                    '--ignore', 'iterm2env',
                    '--ignore', '.git/',
                    '--ignore', 'node_modules/',
                    '--ignore', '__pycache__/',
                    '--ignore', 'target/',
                }
                return ag_vimgrep_args
                -- TODO sync the i"vimgrep" -g "*lua*"gnored/included with nvim-tree plugin too?
            end

            local db_file = vim.fn.stdpath("data") .. "/databases/telescope-smart-history.sqlite3"
            local db_dir = vim.fn.fnamemodify(db_file, ":h")
            if vim.fn.isdirectory(db_dir) == 0 then
                vim.fn.mkdir(db_dir, "p")
            end

            require('telescope').setup({
                defaults = {
                    dynamic_preview_title = true,

                    history = {
                        path = db_file,
                        limit = 1000,
                    },

                    layout_strategy = 'flex', -- based on width (kinda like this actually and it resizes with the window perfectly)
                    -- layout_strategy = 'vertical', -- default is horizontal (files+prompt left, preview right)
                    -- layout_strategy = 'horizontal', -- vertical = (preview top, files middle, prompt bottom) -- maximizes both list of files and preview content
                    layout_config = {
                        -- :help telescope.layout
                        horizontal = { width = 0.9 },
                        vertical = { width = 0.9 },
                    },
                    vimgrep_arguments = rg_search(),
                    -- vimgrep_arguments = ag_search(),
                    mappings = {
                        i = {
                            -- CYCLE history of previous searches: (like command line history)
                            --  use Ctrl-Up/Down so arrows can move through results of current search
                            ["<C-Up>"] = require("telescope.actions").cycle_history_prev,
                            ["<C-Down>"] = require("telescope.actions").cycle_history_next,

                            -- * closing and using both insert/normal mode
                            ["<C-c>"] = require("telescope.actions").close, -- FYI the DEFAULT is <C-c> == close (insert mode), setting here to make it obvious
                            -- how to use normal mode:
                            --   * Esc => normal mode like normal!
                            --   * Ctrl+C to close in both insert/normal mode
                            --     * that way don't need double escape to close it
                            -- pros of using normal mode on pickers:
                            --   * Esc => j/k to move up/down the list! YES
                            --   * PRN? can I setup "Telescope resume" to open in normal mode so I can j/k right away?
                            --      does this feel right if so?
                            --   - run commands on picker, i.e. :nmap ...
                            -- ["<Esc>"] = require("telescope.actions").close, -- NOT DEFAULT, use if want to close on Esc though
                        },
                        n = {
                            -- also map Ctrl-c to close in normal mode, that way it matches the default <C-c> in insert mode
                            ["<C-c>"] = require("telescope.actions").close,
                        }

                    },
                    cache_picker = {
                        num_pickers = 10, -- default 1
                        limit_entries = 100, -- default 1000... I only really need this when I am stepping through meaninngfully filtered lists of results, so 100 is way overkill too
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

                        find_command = {
                            "rg",
                            "--files",
                            "--no-ignore",
                            "--hidden",
                            "--glob", "!**/.git/*",
                            "--glob", "!**/.venv/*",
                            "--glob", "!**/node_modules/*",
                            "--glob", "!**/iterm2env/*",
                            "--glob", "!**/__pycache__/*",
                            -- consider target/debug/ if issues blocking target/ dir entirely
                            "--glob", "!**/target/*",
                        },
                        -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
                        -- PRN use git_files and fallback to find_files: Falling back to find_files if git_files can't find a .git directory, wouldn't this be missing new files?

                        previewer = false, -- PRN make it more like vscode (focus on file names, not content, esp b/c I would do a grep files if I wanted to search by content)
                    },
                },
                extensions = {
                    coc = {
                        theme = 'ivy', -- bottom layout (similar to existing coc references picker layout... but stands out better... can comment this out to go back to floating)
                        -- prefer_locations = true, -- always use Telescope locations to preview definitions/declarations/implementations etc
                        -- push_cursor_on_edit = true, -- think mark_on_select => mark where you jump to when you make a selection (this is on by default, so only false changes this)
                        timeout = 20000, -- timeout for coc commands
                    },

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
            -- set a keymap to builtin.lsp_document_symbols => <leader>lsp_document_symbols => <leader>lds?
            vim.keymap.set('n', '<leader>l', "<Cmd>Telescope coc<CR>", { desc = "Coc pickers" })
            --
            vim.keymap.set('n', '<leader>ls', "<Cmd>Telescope coc document_symbols<CR>", { desc = "Coc document_symbols" })
            vim.keymap.set('n', '<leader>lws', "<Cmd>:Telescope coc workspace_symbols<CR>", { desc = "Coc workspace_symbols" })
            --
            -- WIP trying 'g' for dia[g]nostics
            vim.keymap.set('n', '<leader>lg', "<Cmd>:Telescope coc diagnostics<CR>", { desc = "Coc diagnostics" })
            vim.keymap.set('n', '<leader>lwg', "<Cmd>:Telescope coc workspace_diagnostics<CR>", { desc = "Coc workspace_diagnostics" })
            --
            -- TODO declarations?
            vim.keymap.set('n', '<leader>ld', "<Cmd>:Telescope coc definitions<CR>", { desc = "Coc definitions" })
            vim.keymap.set('n', '<leader>lr', "<Cmd>:Telescope coc references<CR>", { desc = "Coc references" })
            vim.keymap.set('n', '<leader>li', "<Cmd>:Telescope coc implementations<CR>", { desc = "Coc_implementations" })
            vim.keymap.set('n', '<leader>lu', "<Cmd>:Telescope coc references_used<CR>", { desc = "Coc references_used" })
            vim.keymap.set('n', '<leader>ly', "<Cmd>:Telescope coc type_definitions<CR>", { desc = "Coc type_definitions" })
            -- FYI can always leave off specific sub key maps and just do <leader>lx => opens coc pickers list with x prefilled and narrowed to matching pickers, just hit Enter to start it... basically gets you keymaps w/o explicitly setting them
            --  sometimes easier to not have to memorize the sub keymaps and just search the picker picker list... until that's annoying enough that a keymap makes sense


            -- TODO good idea to make picker that searches help/docs (note not just tags)
            --    needs some work...
            -- vim.keymap.set('n', '<leader>hg', function()
            --     -- this adds a custom picker that should be have like :helpgrep
            --     -- TODO WIP help grep... might need new dirs to search
            --     require('telescope.builtin').live_grep({
            --         prompt_title = 'Help Live Grep',
            --         -- default_text = vim.fn.expand('<cword>'), -- TODO do I want to start with word under cursor too?
            --         search_dirs = {
            --             -- vim.fn.stdpath('data') .. '/site/doc',
            --             vim.fn.stdpath('data') .. '/lazy/vimspector/doc',
            --             -- vim.fn.stdpath('config') .. '/doc',
            --             -- vim.fn.expand('$VIMRUNTIME') .. '/doc',
            --             -- ~/.local/share/nvim/lazy/vimspector/doc
            --         },
            --     })
            -- end, { desc = "Help grep, think :helpgrep but with telescope" })


            function live_grep_consolidated(big_word, glob_arg)
                glob_arg = glob_arg or ""

                local mode = vim.fn.mode()
                if mode == "n" then
                    -- in normal mode use word under cursor
                    local current_word = vim.fn.expand(big_word and '<cWORD>' or '<cword>')
                    current_word = "'" .. current_word .. "'"
                    require("telescope").extensions.live_grep_args.live_grep_args({
                        default_text = glob_arg .. current_word
                    })
                    return
                end

                local function is_any_visual_mode()
                    local mode = vim.fn.mode()
                    return mode == "v" or mode == "V" or mode == "^V"
                end

                if is_any_visual_mode() then
                    -- yank to c register
                    vim.cmd("normal! \"cy")

                    local selected_text = vim.fn.getreg('c') or ""

                    -- remove trailing newline, will blow up live grep
                    selected_text = selected_text:gsub("\n", "")

                    -- if selected text has space in it, then wrap it in quotes... and escape any instances of the quoted character
                    if selected_text:find(" ") then
                        selected_text = "'" .. selected_text:gsub("'", "''") .. "'"
                    end

                    require("telescope").extensions.live_grep_args.live_grep_args({
                        default_text = glob_arg .. selected_text
                    })
                    return
                end

                error("unexpected mode: " .. mode)
            end

            vim.keymap.set({ 'n', 'v' }, '<leader>w', function() live_grep_consolidated(false) end)
            vim.keymap.set({ 'n', 'v' }, '<leader>W', function() live_grep_consolidated(true) end)

            function live_grep_current_file(big_word)
                local current_file_path = vim.fn.expand('%')
                local glob_arg = "-g '" .. current_file_path .. "' "
                live_grep_consolidated(big_word, glob_arg)
            end

            vim.keymap.set({ 'n', 'v' }, '<leader>wf', function() live_grep_current_file(false) end)
            vim.keymap.set({ 'n', 'v' }, '<leader>Wf', function() live_grep_current_file(true) end)

            function live_grep_word_under_cursor_same_file_type(big_word)
                local buffers_file_extension = vim.fn.expand('%:e')
                local glob_arg = "-g '*." .. buffers_file_extension .. "' "
                live_grep_consolidated(big_word, glob_arg)
            end

            vim.keymap.set({ 'n', 'v' }, '<leader>wt', function() live_grep_word_under_cursor_same_file_type(false) end)
            vim.keymap.set({ 'n', 'v' }, '<leader>Wt', function() live_grep_word_under_cursor_same_file_type(true) end)
        end,
    },

    {
        -- use coc as the LSP client for telescope pickers (vs OOB builtin which uses nvim LSP client)
        "fannheyward/telescope-coc.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("telescope").load_extension("coc")
        end,
    },

    {
        "g0t4/telescope-picker-picker.nvim",
        enabled = true,
        -- dir = "~/repos/github/g0t4/telescope-picker-picker.nvim",
        event = { "VeryLazy" },
        opts = {},
        config = function()
            -- not required, but makes it possible to do `:Telescope p<TAB>` and see it in list of choices
            require("telescope").load_extension("picker_picker")
        end
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
                -- TODO add a <leader>si/sg maybe... open with -i on front plus current word? or -g "*filetype*" already in there?
                --   TODO OR... add abbreviations specific to JUST the live_grep window to expand these for me
                -- FYI! live grep args is  finnicky arg parsing...
                --  You would think these would do the same thing:
                --    "vimgrep" -g "*lua*"
                --    vimgrep -g "*lua*"
                --    -g "*lua*" vimgrep
                --    the first and last work, the middle is treated as one giant content match arg! hence it doesn't work
                --  start with '/"/- to have it parse and use args to ag/rg command
                --  ALSO, remember with rg, it uses a glob for the file path match
                --    so no partial matches
                --    you have to do -g "*lua*" not `-g lua` which SUCKS but w/e
                --  PRN rewrite this extension to behave more logically how I'd prefer it?
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
