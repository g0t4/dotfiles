---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global

require("early")
require("bootstrap-lazy")

do return end

-- per nvim-tree docs:
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true -- s/b already enabled in most of my environments, maybe warn if not?


local packer = require 'packer'
packer.startup(function()
    -- on changes, resource this file and :PackerSync
    -- :PackerCompile
    -- :PackerClean   (remove unused)
    -- :PackerInstall (install new)
    -- :PackerUpdate
    -- :PackerSync (update+compile)
    --     nvim observation: install window opens and can use `q` to close without :q

    -- packer manages packer, is that wise?
    -- w/o this packer asks to remove packer, so I added this, run :PackerCompile, then :PackerSync and it doesn't ask to remove packer now
    use 'wbthomason/packer.nvim'

    use 'Mofiqul/vscode.nvim'     -- use "vscode" ... I added this in neovim, though my other theme is fine too it seems
    use 'tomasiser/vim-code-dark' -- use "codedark" from my vimrc

    use 'github/copilot.vim'


    ---
    -- alternative but only has completions? https://neovimcraft.com/plugin/hrsh7th/nvim-cmp/ (example config: https://github.com/m4xshen/dotfiles/blob/main/nvim/nvim/lua/plugins/completion.lua)
    use { 'neoclide/coc.nvim', branch = 'release' } -- LSP (language server protocol) support, completions, formatting, diagnostics, etc
    -- 0.0.82 is compat with https://microsoft.github.io/language-server-protocol/specifications/specification-3-16/
    -- https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim (install extensions)
    -- sample config: https://raw.githubusercontent.com/neoclide/coc.nvim/master/doc/coc-example-config.vim
    vim.cmd([[
        " *** FYI coc.nvim doesn't modify key-mappings nor vim options, hence the need to specify config explicitly, fine by me!

        " FYI
        "  :CocList extensions  " and others
        "  :CocInstall coc-lua   " wow gutter icons showed right up!
        "     https://github.com/josa42/coc-lua
        "     https://github.com/LuaLS/lua-language-server  # LSP backend, use this for options (ie diagnostics config)
        "  :CocInstall coc-vimlsp
        "     https://github.com/iamcco/vim-language-server
        "  :CocInstall coc-fish " shows man pages on Shift+K!! cool
        "  :CocInstall coc-pyright
        "  :CocInstall coc-toml coc-yaml coc-json
        "  :CocInstall coc-svg
        "  :CocInstall coc-docker
        "
        " TRY:
        "   list here: https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions#implemented-coc-extensions
        "   ??? https://github.com/yuki-yano/coc-copilot
        "   ??? https://github.com/neoclide/coc-tabnine
        "   coc-sh (bash)   coc-powershell
        "   coc-omnisharp (c#,vb)
        "   coc-nginx
        "   coc-rust-analyzer?
        "   coc-tsserver (typescript, javascript)
        "   lua alternative: https://github.com/xiyaowong/coc-sumneko-lua
        "   mardownlint / markdown-preview-enhanced / markmap (mindmap + markdown)
        "   spelling: coc-ltex / coc-spell-checker

        " Some servers have issues with backup files, see #649
        set nobackup
        set nowritebackup

        " Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
        " delays and poor user experience
        set updatetime=300

        " Always show the signcolumn, otherwise it would shift the text each time
        " diagnostics appear/become resolved
        set signcolumn=yes

        "
        "" TODO how to reconcile coc + copilot?
        ""
        "" Use tab for trigger completion with characters ahead and navigate
        "" NOTE: There's always complete item selected by default, you may want to enable
        "" no select by `"suggest.noselect": true` in your configuration file
        "" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
        "" other plugin before putting this into your config
        "inoremap <silent><expr> <TAB>
        "      \ coc#pum#visible() ? coc#pum#next(1) :
        "      \ CheckBackspace() ? "\<Tab>" :
        "      \ coc#refresh()
        "inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

        " Make <CR> to accept selected completion item or notify coc.nvim to format
        " <C-g>u breaks current undo, please make your own choice
        inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                      \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

        function! CheckBackspace() abort
          let col = col('.') - 1
          return !col || getline('.')[col - 1]  =~# '\s'
        endfunction

        " Use <c-space> to trigger completion
        if has('nvim')
          inoremap <silent><expr> <c-space> coc#refresh()
        else
          inoremap <silent><expr> <c-@> coc#refresh()
        endif

        " TODO try out diagnostics
        " Use `[g` and `]g` to navigate diagnostics
        " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
        nmap <silent> [g <Plug>(coc-diagnostic-prev)
        nmap <silent> ]g <Plug>(coc-diagnostic-next)

        " TODO try out navigation
        " GoTo code navigation
        nmap <silent> gd <Plug>(coc-definition)
        nmap <silent> gy <Plug>(coc-type-definition)
        nmap <silent> gi <Plug>(coc-implementation)
        nmap <silent> gr <Plug>(coc-references)

        " Use K to show documentation in preview window
        nnoremap <silent> K :call ShowDocumentation()<CR>

        function! ShowDocumentation()
          if CocAction('hasProvider', 'hover')
            call CocActionAsync('doHover')
          else
            call feedkeys('K', 'in')
          endif
        endfunction


        " disabled for now, multiline strings in lua aren't recognized as nested code which makes sense... so any time cursor stops in the multiline string it higlights all of it (yuck)
        " Highlight the symbol and its references when holding the cursor
        "autocmd CursorHold * silent call CocActionAsync('highlight')

        " switched to lua with format key maps

    ]]) -- coc needs this, "Some servers have issues with backup files, see #649", sitll have swapfile in case of failure

    vim.keymap.set('n', '<S-M-f>', ":call CocAction('format')<CR>", { desc = 'Coc format (normal mode)' }) -- vscode format call...can this handle selection only?
    vim.keymap.set('i', '<S-M-f>', "<Esc>:call CocAction('format')<CR>a", { desc = 'Coc format (insert mode)' })

    -- TODO vim freezes when I use this for local a below
    -- rename:
    vim.keymap.set('n', 'C-r,C-r', ":call CocAction('rename')<CR>", { desc = 'Coc rename' })

    -- TODO review lua config for many other code action helpers... I skipped most for now

    -- Add `:Format` command to format current buffer
    vim.api.nvim_create_user_command("Format", "call CocAction('format')", {})

    -- " Add `:Fold` command to fold current buffer
    vim.api.nvim_create_user_command("Fold", "call CocAction('fold', <f-args>)", { nargs = '?' })

    -- Add `:OR` command for organize imports of the current buffer
    vim.api.nvim_create_user_command("OR", "call CocActionAsync('runCommand', 'editor.action.organizeImport')", {})


    -- *** surround related extensions
    --
    -- surround with - add/rm () {} [] `` '' "" etc - like vscode, I really like that in vscode, esp in markdown to use code blocks on existing content
    use 'kylechui/nvim-surround' -- dot repeat! (wrap multiple things), jump to nearest pair?
    require('nvim-surround').setup({})

    -- use 'machakann/vim-sandwich' -- alternative?
    --
    -- PRN revisit autoclose, try https://github.com/windwp/nvim-autopairs (uses treesitter, IIUC)
    -- -- https://github.com/m4xshen/autoclose.nvim
    -- use 'm4xshen/autoclose.nvim' -- auto close brackets, quotes, etc
    -- require('autoclose').setup({
    --   -- ? how do I feel about this and copilot coexisting? seem to work ok, but will closing it out ever be an issue for suggestions
    --   -- ? review keymaps for conflicts with coc/copilot/etc
    --   filetypes = { 'lua', 'python', 'javascript', 'typescript', 'c', 'cpp', 'rust', 'go', 'html', 'css', 'json', 'yaml', 'markdown' },
    --   ignored_next_char = "[%w%.]", -- ignore if next char is a word or period
    --
    --   -- ' disable_command_mode = true, -- disable in command line mode AND search /, often I want to search for one " or [[ and dont want them closed
    --
    -- })
    --
    -- FYI I don't need autoclosing tags, copilot does this for me, and it suggests adding them after I add the content
    --   PLUS when I use auto close end tag, it conflicts with copilot suggestions until I break a line... so disable this for now
    --   PRN maybe I can configure this to do renames only? (not add on open tag), that said how often do I do that, I dunno?
    -- use 'windwp/nvim-ts-autotag' -- auto close html tags, auto rename closing too
    -- require('nvim-ts-autotag').setup()

    -- TODO paste with indent?

    use {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        requires = {
            { 'nvim-lua/plenary.nvim' },
        },
        -- use `:checkhealth telescope` to verify deps

        -- extensions: https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions
    }
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
    --
    vim.cmd("let g:mapleader = ' '") -- default is '\' which is a bit awkward to reach, gotta take right hand off homerow
    --
    vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Telescope find files' })
    vim.keymap.set('n', '<C-S-p>', builtin.commands, { desc = 'Telescope commands' }) -- PRN try this out, see if I like it better
    --
    vim.keymap.set('n', '<leader>t', builtin.builtin, { desc = 'Telescope Builtin' }) -- list pickers, select one opens it (like if :Telescope<CR>), shows keymaps too
    --
    -- FYI habituate Ctrl+V (open vertical split diff!)
    vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope live grep' }) -- proj search
    -- PRN ag? https://github.com/kelly-lin/telescope-ag  (extension  to telescope) => others https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions
    --
    use 'catgoose/telescope-helpgrep.nvim'
    -- PRN redirect F1 to this? or maybe F1 to grep help tags? .. what does F1 currently map to?
    require('telescope').load_extension('helpgrep')                                              -- ensure shows in :Telescope list/completion
    vim.keymap.set('n', '<leader>h', ":Telescope helpgrep<CR>", { desc = 'Telescope helpgrep' }) -- not just help tags! (btw help tags already works via cmd line, dont need it here too)
    --
    vim.keymap.set('n', '<leader>s', builtin.git_status, { desc = 'Telescope git status' })
    --
    --
    use 'xiyaowong/telescope-emoji.nvim'
    require("telescope").load_extension("emoji")
    vim.keymap.set('n', '<leader>te', ":Telescope emoji<CR>") -- use `<leader>t*` for less used pickers, may be slow due to overlap in <leader> keymaps but NBD
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


    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    } -- treesitter (syntax highlighting, etc)

    -- TSModuleInfo shows what features (highlight, illuminate[if plugin enabled], indent, incremental_selection)
    require 'nvim-treesitter.configs'.setup {
        ensure_installed = { "c", "lua", "python", "javascript", "typescript", "html", "css", "json", "yaml", "markdown", "vim" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
        sync_install = false,
        auto_install = true,                                                                                                       -- PRN try tree-sitter CLI too, outside of neovim
        -- ignore_install
        highlight = {
            enable = true, -- enable for all
            disable = {},  -- confirmed TSModuleInfo shows X for these languages
        },
        -- additional_vim_regex_highlighting = false, -- not having any effect on my regex highlighting... is that intended?
        -- doesn't look like it's doing anything right now.. no languages are marked as highlighted (nor anything else)
    }
    -- ** TODO completions
    -- ** TODO reformat files
    -- ** LSP (nav, completions,etc)
    -- ** higlighting (for my custom comments at least, probably port this to an existing extension is best) - I bet some manage diff syntax types (treesitter, vim regex, syntect? sublimetext)

    use {
        'nvim-treesitter/playground',
        after = 'nvim-treesitter'
    } -- playground for treesitter (try out treesitter queries)
    -- :TSHighlightCapturesUnderCursor

    -- markdown rendering:
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim
    --
    -- previewer: look promising https://github.com/jannis-baum/vivify.vim
    --
    -- deno based: https://github.com/toppair/peek.nvim?tab=readme-ov-file ... might be good, appears to maybe have builtin window preview?
    use {
        "toppair/peek.nvim",
        -- event = "VimEnter",
        run = "deno task --quiet build:fast",
        config = function()
            require("peek").setup()
            vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
            vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
        end
    }
    require('peek').setup({
        auto_load = true,        -- whether to automatically load preview when
        -- entering another markdown buffer
        close_on_bdelete = true, -- close preview window on buffer delete

        syntax = true,           -- enable syntax highlighting, affects performance

        theme = 'dark',          -- 'dark' or 'light'

        update_on_change = true,

        app = 'browser',
        -- app = 'webview',          -- 'webview', 'browser', string or a table of strings
        -- explained below

        filetype = { 'markdown' }, -- list of filetypes to recognize as markdown

        -- relevant if update_on_change is true
        throttle_at = 200000,   -- start throttling when file exceeds this
        -- amount of bytes in size
        throttle_time = 'auto', -- minimum amount of time in milliseconds
        -- that has to pass before starting new render
    })

    -- TODO FORMATTER focused extension:
    -- use 'stevearc/conform.nvim' -- can replace LSP formatters that are problematic, per file type... DEFINITELY LOOK INTO THIS

    -- TODO COMMENT alternatives:
    -- use 'numToStr/Comment.nvim' -- more features like gc$ (not entire line)
    -- use 'JoosepAlviste/nvim-ts-context-commentstring' -- context aware commentstring, IIUC for issues with embedded languages and commenting... FYI embedded vimscript in lua, gcc works fine

    -- TODO git related
    -- use "tpope/vim-fugitive" =>
    -- use "lewis6991/gitsigns.nvim" -- git code lens essentially, never been a huge fan of that in vscode

    -- PRN bufferline? tab strip with buffers (in addition to tabs)... interesting, gotta think if I want this, I kinda like it right now because I can see what files I have open... I would also wanna know key combos (or set those up for switching buffers, vs tabs)... I need to learn better what the intent is w/ a buffer vs tab, the latter you can :q to quit but the former is like multiple per tab (one :q closes all buffers)... also have :bdelete (close), etc
    -- keep for now as a reminder I wanna figure out how to work with a multi open doc system in vim now, later (like vscode), I suspect I will get rid of the tab strip? or just go to showing current file name in title of entire app would be fine too
    -- use {'akinsho/bufferline.nvim', tag = "*", requires = 'nvim-tree/nvim-web-devicons'}
    -- require("bufferline").setup({})

    -- PRN cursor line (highlight selected line AND also does illuminate task of showing current word (under cursor) occurrences underlined)
    -- yamatsum/nvim-cursorline

    -- TODO review list of extensions here:
    -- https://nvimluau.dev/akinsho-bufferline-nvim (TONS of extensions and alternatives including statusline, bufferline, etc
    --
    -- https://nvimluau.dev/meznaric-conmenu  # context menu for nvim (ie format,  code actions, would this be useful?)
    -- https://nvimluau.dev/hood-popui-nvim  # boxes around UI elemennts like hover boxes?
    --
    -- mark unique letters to jump to:
    --  use "unblevable/quick-scope" -- quick scope marks jump
    use "jinh0/eyeliner.nvim"   -- lua impl, validated this actually works good and the color is blue OOB which is nicely subtle, super useful on long lines!
    --
    use "karb94/neoscroll.nvim" -- smooth scrolling? ok I like this a bit ... lets see if I keep it (ctrl+U/D,B/F has an animated scroll basically) - not affect hjkl/gg/G
    -- also works with zb/zt/zz which I wasn't aware of but looks useful => zz = center current line! zt/zb = curr line to top or bottom... LOVE IT!
    -- this scratches an itch I had about how it is hard to tell where I am jumping to with page up/down half page up /down etc... this makes it obvious where the movement is headed, long term I might become annoyed by this but its a useful idea... after all we have half page up/down me thinks for a reason that you can see the scroll easier than one full page jump
    require('neoscroll').setup()
    --


    -- PRN indent guides (vertically, like vscode plugin)
    -- use "lukas-reineke/indent-blankline.nvim"

    -- PRN customize statusline plugin (though I don't care for a bunch of crap I don't need to see, i.e. git branch shouldn't waste screen space)
    -- use "nvim-lualine/lualine.nvim" -- maybe useful for small customizations, i.e. I wanna show selected char count in visual selection mode

    -- PRN catppuccin/nvim # UI themes, might have smth good or ideas for my own theme mods

    -- PRN mrjones2014/smart-splits.nvim => better way to manage splits with tmux and nvim? not sure I need this but maybe ideas for doing similar in iterm2?

    -- HRM... tris203/precognition.nvim => shows keys to use to jump to spots... might be a good way for beginners to learn about what keys to use in a situation?





    --   works, some samples for embedded docs are indented and work when unindented FYI
    --   not necessary to `npx yarn build`... `npm install` worked fine for me in the app dir as is show here:
    --   discussion about if unmaintained... works though so YMMV: https://github.com/iamcco/markdown-preview.nvim/issues/688
    use {
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function()
            vim.g.mkdp_filetypes = {
                "markdown" }
        end,
        ft = { "markdown" },
    }









    -- gelguy/wilder.nvim  # compare to builtin picker and fuzzy finder instead?
    --    port config from vimrc if I use this
    --    can I setup wilder to not show unless I hit tab? I like how that works in nvim's menu picker OOB
    --
    -- Plugin 'ryanoasis/vim-devicons'
    --
    -- Plugin 'tpope/vim-commentary'  # switch to this if I don't like bundled comment in neovim
    --
    -- editorconfig? (bundled, right?)

    -- TSModuleInfo shows nothing setup?! including nothing for lua?
    -- :scriptnames # shows loaded files BTW => useful to see if syntax/lua.vim loaded (how I found it uses ftplugin/lua.lua to specify tree sitter)
    --
    -- :TSInstall lua
    -- :TSBufEnable highlight # now TSModuleInfo shows lua!... TODO what is gonna be different? I need to research what to expect and see if I can even identify differences
    --
    -- FYI markdown (via :scriptnames) seems to load vim syntax definitions (unlike lua)
    --    THOUGH, on disk there are syntax/ lua.vim definitions too, just not loaded by default (IIAC b/c ftplugin/lua.lua says to use tree sitter instead)
    --
    -- :TSInstallInfo
    --


    -- force myself to learn hjkl to move up/down/left/right at least in normal mode?,
    -- vim.keymap.set('n', '<up>', '')    -- disable up arrow
    -- vim.keymap.set('n', '<down>', '')  -- disable down arrow
    -- vim.keymap.set('n', '<left>', '')  -- disable left arrow
    -- vim.keymap.set('n', '<right>', '') -- disable right arrow

    -- hardtime
    -- use 'takac/vim-hardtime' -- timer, disable keys
    use { 'm4xshen/hardtime.nvim', -- tons of features, recommends, block repeated key use, etc
        requires = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    }
    require("hardtime").setup()
    --



    -- which-key.nvim
    use {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup {
                delay = 1000, -- before open (ms)

                plugins = {
                    presets = {
                        motions = true, -- show help for motions too => type `d` and wait (although it doesn't show d again for line?)
                    }
                }

                -- default configures keymap triggers for every mode
                --   so when you pause mid key combo, it pops open... not if you rapidly enter the key combo
                --   also gives you time to look and pick w/o timeout on keys (IIGC timeoutlen limits this)
                --   would be good to increase delay me thinks, lets wait and see though
                --        delay = function(ctx)
                --             return ctx.plugin and 0 or 200
                --           end,

                --
                --   pulls desc attr of each map, so set those!
                -- opts.triggers includes { "<auto>", mode = "nixsotc" },
                -- optional - for icons - mini.icons or nvim-web-devicons
            }
        end
    }


    -- highlight just word under cursor:
    use "RRethy/vim-illuminate" -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column
    --    sadly, not the current selection (https://github.com/RRethy/vim-illuminate/issues/196), I should write this plugin
    --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
    --    customizing:
    --      hi def IlluminatedWordText gui=underline
    --      hi def IlluminatedWordRead gui=underline
    --      hi def IlluminatedWordWrite gui=underline
    --

    -- highlight selections like vscode, w/o limits (200 chars in vscode + no new lines)
    use "aaron-p1/match-visual.nvim" -- will help me practice using visual mode too
    -- FYI g,Ctrl-g to show selection length (aside from just highlighting occurrenes of selection)

    use "norcalli/nvim-colorizer.lua" -- colorize hex codes, etc
    require("colorizer").setup()

    -- maybe:
    --  tjdevries/colorbuddy.nvim -- make it easier to define new color schemes
    --  nacro90/numb.nvim -- peek line #s while go to (:123) and hide again after, also other peeks (cursorline)
    -- TODO: foo the bar
    --
    -- TODO other (TODO set so not need trailing colon?)
    --
    -- FIXME fo asdf foajho
    -- NOTE foo
    -- CUSTOM foo the bar
    -- use {
    --     "folke/todo-comments.nvim",
    --     requires = "nvim-lua/plenary.nvim",
    --     config = function()
    --         require("todo-comments").setup {
    --             highlight = {
    --                 -- before = "bg",
    --                 keyword = "bg",
    --                 after = "bg",
    --                 pattern = [[.*<(KEYWORDS)\s*]],
    --             },
    --             signs = false, -- show icons in the gutter
    --             -- You can add custom keywords and styles here
    --             keywords = {
    --                 -- TODO = { icon = " ", color = "info" },
    --                 -- FIXME = { icon = " ", color = "error" },
    --                 -- NOTE = { icon = " ", color = "hint" },
    --                 -- CUSTOM = { icon = " ", color = "warning" }, -- Custom keyword example
    --             },
    --         }
    --     end
    -- }
end)
-- TODO: port from vimrc

-- *** color scheme
vim.cmd('colorscheme codedark') -- beautiful!
-- set termguicolors -- seems already set (tested in iterm2)
--

-- FYI has('mouse') => nvi which is very close to what I had in vim ('a') ... only change if issue arises

--- clipboard
vim.o.clipboard = 'unnamedplus' -- use system clipboard
-- TODO what do I want for clipboard?

-- wrap settings
vim.o.wrap = false  -- global nowrap, consider local settings for this instead
vim.o.textwidth = 0 -- disable globally, add back if I find myself missing it

-- *** tabs
-- I chose option 2 (always insert spaces, leave tabs as is with default tabstop=8)
vim.o.expandtab = true -- insert spaces for tabs
vim.o.softtabstop = 4  -- b/c expandtab is set, this is the width of an inserted tab in spaces
vim.o.shiftwidth = 4   -- shifting: << >>
-- vim.o.tabstop -- leave as is (8) so existing uses of tabs match width likely intended

-- *** show whitespace
vim.opt.listchars = { tab = '→ ', trail = '·', space = '⋅' } -- FYI also `eol:$`
vim.cmd("command! ToggleShowWhitespace if &list | set nolist | else | set list | endif")

-- TODO: port from vimrc
-- " *** review `autoindent`/`smartindent`/`cindent` and `smarttab` settings, I think I am fine as is but I should check
--     filetype plugin indent on " this is controlling indent on new lines for now and seems fine so leave it as is
--     set backspace=indent,start,eol " allow backspacing over everything in insert mode, including indent from autoindent, eol thru start of insert

--[[
NOTES (vimscript => lua)

vim.cmd({cmd}) to execute a vimscript command

vim.o (== :set)
    https://neovim.io/doc/user/lua.html#vim.o
vim.opt for list/map options (access as lua tables, i.e. append/prepend/remove elements)
    https://neovim.io/doc/user/lua.html#vim.opt
]] --

vim.cmd([[
    " TODO fix when close the original file doesn't show
    command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                  \ | wincmd p | diffthis
]])





-- *** Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file
vim.cmd("nnoremap <c-s> :w<CR>")
vim.cmd("vnoremap <c-s> <Esc><c-s>gv") -- esc=>normal mode => save => reselect visual mode, not working... figure out later
vim.cmd("inoremap <c-s> <c-o><c-s>")




-- map [Shift]+Ctrl+Tab to move forward/backward through files to edit, in addition to Ctrl+o/i
--   that is my goto key combo, perhaps I should learn o/i instead... feel like many apps use -/+ for this, vscode for shizzle
vim.api.nvim_set_keymap('n', '<C-->', '<C-o>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-->', '<C-i>', { noremap = true, silent = true })
--  FYI in iTerm => Profiles -> Keys -> Key Mappings -> removed "send 0x1f" on "ctrl+-" ... if that breaks something, well you have this note :)


-- *** ASK OPENAI wrapper
vim.cmd([[
    " nvim observation: nested languages in lua are highlighted nicely!
    "   lua observation: multiline strings rock for embedding other languages

    " TODO review prompt and see if I should specify this is neovim vs classic... in fact I should update this wrapper to differentiate and pass that

    function! TrimNullCharacters(input)
        " Replace null characters (\x00) with an empty string
        " was getting ^@ at end of command output w/ system call (below)
        return substitute(a:input, '\%x00', '', 'g')
    endfunction

    function! AskOpenAI()

        let l:cmdline = getcmdline()

        " todo this prompt here should be moved into vim.py script and combined with other system message instructs? specifically the don't include leading :? or should I allow leading: b/c it still works to have it
        let l:STDIN_text = ' env: nvim (neovim) command mode (return a valid command w/o the leading : ) \n question: ' . l:cmdline

        " PRN use env var for DOTFILES_DIR, fish shell has WES_DOTFILES variable that can be used too
        let l:DOTFILES_DIR = '~/repos/wes-config/wes-bootstrap/subs/dotfiles'
        let l:py = l:DOTFILES_DIR . '/.venv/bin/python3'
        let l:vim_py = l:DOTFILES_DIR . '/zsh/universals/3-last/ask-openai/vim.py'
        let l:command_ask = l:py . ' ' . l:vim_py

        let l:result = system(l:command_ask, l:STDIN_text)

        return TrimNullCharacters(l:result)

    endfunction

    " Map a key combination to the custom command in command-line mode
    cmap <C-b> <C-\>eAskOpenAI()<CR>

]])

-- cursor block in insert:
vim.cmd(":set guicursor=i:block")


vim.cmd([[

    "PAGE UP... find a diff way wes    ":nnoremap <C-d> :quit<CR>

    " *** fix delete key reporting
    "    it reports 63272 which isn't mapped to <Del>
    "    :echo getchar()  => type the delete key => shows 63272 (whereas vim classic shows <80>kD)
    "       interesting, insert key (above delete) shows <80>kI ... which vim classic also reports, likewise pgup/pgdown show <80>kP/<80>kN in both
    inoremap <Char-63272> <Del>
    cnoremap <Char-63272> <Del>
    " in normal mode, just del current char
    nnoremap <Char-63272> x
    "
    " *** show key reported:
    command! ShowKeyWes echo getchar()
    "
    " *** alt key troubles
    "   fixed w/ iterm setting for now...
    "       Profiles -> Keys -> Left Option Key: Meta (then alt+right works accept-word,  also alt+[/] cycles suggestions, and ctrl+alt+right accepts next line)
    "   fixes several default copilot keybindings
    "   notes:
    "     getchar() w/ alt+right =>
    "         <80><fc>^H<80>kr     " with the iterm setting fix
    "                   <80>kr     " w/o the iterm setting fix
    "         btw, vim classic always has the longer version regardless of iterm2 setting



    "" copilot consider map to ctrl+enter instead of tab so IIUC other completions still work, O
    "imap <silent><script><expr> <C-CR> copilot#Accept("\\<CR>")
    "let g:copilot_no_tab_map = 1
    "" ok I kinda like ctrl+enter for copilot suggestions (vs enter for completions in general (coc)) but for now I will put tab back and see if I have any issues with it and swap this back in if so

    function! ToggleCopilot()
        " FYI https://github.com/github/copilot.vim/blob/release/autoload/copilot.vim

        " FYI only global toggle, not toggling buffer local

        " PRN save across sessions? maybe modify a file that is read on startup (not this file, I want it out of vimrc)

        if copilot#Enabled()
            Copilot disable
        else
            Copilot enable
        endif

        " echo "copilot is: " . (g:copilot_enabled ? "on" : "off")
        Copilot status " visual confirmation - precise about global vs buffer local too
    endfunction

    :inoremap <F12> <Esc>:call ToggleCopilot()<CR>a
    " :inoremap <F12> <C-o>:call ToggleCopilot()<CR> " on empty, indented line, causes cursor to revert to start of line afterwards
    :nnoremap <F12> :call ToggleCopilot()<CR>

]])


-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    local myTable = vim.treesitter.get_captures_at_cursor()
    for key, value in pairs(myTable) do
        print(key, value)
    end
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")
local ts = vim.treesitter

local ts_utils = require 'nvim-treesitter.ts_utils'

-- TODO format vimscript (nested in lua)
-- ***! foo

-- TODO! test lua comment
-- TODO test too
-- TODO! treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. so how does that relate to my syntax/highlight groups? how do I see that?
vim.cmd [[

    " FYI if I can also remove @comments capture linkage https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/lua/highlights.scm#L229-L230
    " TODO add custom capture that targets subset of comments insted of using regex, so I can target both syntax and/or treesitter highlight systems

    " !!! TMP fix sets no bg color on comments ... which means here then in nested multiline vimscript lua's orange color applies which is fine ish
    " FYI! NBD that color is orange here... I can fix the overlapping priority later... heck even the lua issue isn't a deal breaker as all other files seem to not have issue (yet, maybe treesitter on them will cause issues)
    " * override Comment color => changes the fg!
    "hi Comment ctermfg=65 guifg='#6a9955'   "original => Last set from ~/.local/share/nvim/site/pack/packer/start/vim-code-dark/colors/codedark.vim
    " hi Comment ctermfg=65 guibg='#6a9955' guifg='#0101ff' "!!! bgcolor takes precedence too, so its a precedence issue IIGC
    " hi Comment ctermfg=65 guifg='#0101ff' gui=NONE " NONE doesn't take precedence, is that even valid though?
    hi clear Comment " clear it fixes the fg color ... b/c then yeah a comment doesn't have a fg color... ok... but can I add back color as a lower precedence rule?
    " OMG OMG  if I break this style with invalid guifg!! my styles work in lua!!!! **tears** (all damn day beating around this bush)


    " explore capture => highlighting
    " captures are linked to existing highlight groups (IIUC for the most part), i.e.:
    ":hi TestNewHigh gui=bold guibg=red guifg=blue " create new highlight rule
    ":hi link @comment TestNewHigh  " link capture to it
    " FYI here is logic to add higlighting to a node: (is this used by extensions?)  https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua#L268

]]

-- FYI! foo
-- !!! FOO
-- alternative way to replace higlight group:
-- -- vim.api.nvim_set_hl(0, "Comment", {})
-- -- vim.api.nvim_set_hl(0, "Comment", { fg = "#6a9955" })
-- vim.api.nvim_set_hl(0, "@comment", {})

function print_ts_cursor_details()
    -- FYI, use :InspectTree => :lua vim.treesitter.inspect_tree() => interactive select/inspect left/right split
    local node_at_cursor = ts_utils.get_node_at_cursor()
    if node_at_cursor then
        print("Node type: ", node_at_cursor:type())
        print("node text: ", vim.treesitter.get_node_text(node_at_cursor, 0)) -- shows the original source! FYI 0 = buffer with text, node lookup into that buffer IIUC
    else
        print("No node found")
    end

    -- API: https://neovim.io/doc/user/api.html
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

    -- FYI drop local to snoop on variables, i.e. parser:
    local parser = ts.get_parser(0)
    local lang_tree = parser:language_for_range({ cursor_row - 1, cursor_col, cursor_row - 1, cursor_col })
    if lang_tree then
        local lang_name = lang_tree:lang()
        print("language: ", lang_name)
    else
        print("language: unknown")
    end


    print("captures:")
    print_captures_at_cursor()

    -- TODO can I get highligther info from treesitter? too? think what I did below but for treesitter
    -- local id = parser:syntax_tree():get_property("highlighter"):query("highlighter", cursor_row, cursor_col)
    -- print(id)

    print("syntax highlighting (not treesitter highlighting):")
    print("name gui:'", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, false), "name", "gui"),
        "' - cterm:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, false), "name", "cterm"))

    print("highlight:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "highlight", ""))
    print("fg:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "fg", "gui"),
        "bg:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bg", "gui"))
    -- print("fg#:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "fg#", "gui"),
    --     "bg#:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bg#", "gui"))
    print("bold:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bold", ""))
    print("italic:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "italic", ""))
    print("underline:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "underline", ""))
    print("undercurl:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "undercurl", ""))

    -- TODO!  test lua commment

    -- IIAC => if have multi syntax/highlight regex hits... then I can show them all here... but won't show any treesitter highlights
    local stack = vim.fn.synstack(cursor_row, cursor_col)
    -- print("length:", #stack)
    -- -- loop:
    for key, value in pairs(stack) do
        print("stack:", key, value, vim.fn.synIDattr(value, "name", "gui"))
    end
end

vim.cmd("nnoremap <leader>pd :lua print_ts_cursor_details()<CR>")

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        vim.cmd("source ~/.config/nvim/highlights.vim")
    end
})



-- CocConfig (opens coc-settings.json in buffer to edit) => from ~/.config/nvim/coc-settings.json
--   https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim#add-some-configuration
--   it works now (Shift+K on vim.api.nvim_win_get_cursor(0) shows the docs for that function! and if you remove the coc-settings.json and CocRestart then it doesn't show docs... yay
--   why? to provide the LSP with vim globals (i.e. to show docs Shift+K) and for coc's completion lists
--
-- FYI all language server docs: https://github.com/neoclide/coc.nvim/wiki/Language-servers#lua
--    each LSP added can be configured in coc-settings.json






-- vim.api.nvim_set_hl(0, "vimAutoCmd",{ fg = "red", bg = "red"})

-- TODO
-- load wilder.vim:
-- vim.cmd('source /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/nvim/todo_vimrc.vim')

-- HIGHLIGHT 3 (maybe) => ultimately I need to understand what all is fighting over highlights/syntax/etc (treesitter, vim regex syntax, LSP too?, syntect (sublime text)..)
--     autocmd filetype    -- super helpful way to see what is applied in what order (where I found the autocmds were registered too early... so maybe put back earlier registration and see if I can find the things in between that are overriding higlights)
--         IN FACT => do binary search on registration order in the plugin chain... see if I can narrow the extension causing issues, IIAC
-- " !!! try AFTER plugin config:
--
-- use {
--   'plugin-to-load-second',
--   after = 'plugin-to-load-first',
--   config = function()
--     -- Your Vimscript or Lua code that depends on `plugin-to-load-first`
--     vim.cmd('echo "Plugin loaded after plugin-to-load-first"')
--   end
-- }
-- OBSERVATIONS:
--   both bg and gui=bold are applied correctly to lua files... just the fg color?!
--   nvim -u NONE ~/.config/nvim/init.lua
--     run w/ no plugins => then
--       :source  ~/.config/nvim/immediate.highlights.vim
--            WORKS! applies my style to FYI below

--
-- HIGHLIGHT ISSUE 2 => lua seems to have smth else styling it and that is overrding fg colors... I dont think its treesitter b/c I configured it to disable it and this still persisted..
--
--
-- HIGHLIGHT ISSUE 1 => most files the style didn't apply (until I discovered you reload the file and that registers the autocmd FileType entries again and that must be overrdiing whatever is blocking the first registration which was before many plugin highlights...)
-- ensure highlight style applied late in load process (before buffer ready but just after file read)...  b/c right now if these are registered earlier (ie before packer plugins...) then the style wont take effect until next file opened
--
--

vim.cmd [[
    "" todo setup auto session extension instead? AND an extension for tracking session history (*like vscode recent folders feature*)...
    "" hopefully something has a telescope compat picker to select the session to restore?
    "
    "" Automatically save session when leaving Vim
    "autocmd VimLeavePre * if (isdirectory(".git") || filereadable(".git")) | mksession! session.vim | endif
    "
    "" Automatically load session when opening Vim in a Git repository
    "autocmd VimEnter * if filereadable("session.vim") | source session.vim | endif
    "
    "" highlighting doesn't work on first load of session (until e! or run filetype detect)
    "autocmd SessionLoadPost * silent! filetype detect
]]

-- -- *** folding config
-- --   (move to treesitter config?)
-- --   https://neovim.io/doc/user/fold.html
-- --   TODO setup per filetype? limit to lua for now?
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
-- -- vim.o.foldenable = false -- no autofolding, just manual after open file
-- -- TODO setup saving folds, sessionoptions has folds but... those might be diff folds? (b/c I tried foldopen command and then zo/zc no longer worked until restart vim, is there a sep fold system?)
--
--

-- nvim loads lua modules first from its runtimepath in a lua/ dir (if in a given rtp dir) => TLDR ~/.config/nvim/lua/ is checked first (assuming ~/.config/nvim is first dir in rtp)
-- FYI these dont show in :scriptnames... not sure they should (would be an explosion of modules if requires showed up there)
require('github-links')
