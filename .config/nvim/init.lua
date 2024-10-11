---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
--- " FYI!
---  can I block specific globals (i.e.  vim/use/etc)

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
    -- alternative but only has completions? https://neovimcraft.com/plugin/hrsh7th/nvim-cmp/
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

    local foo = "1"
    local bar = foo
    -- " define keymap for foo to trigger format in orma
    -- TODO xmode too?
    vim.keymap.set('n', '<S-M-f>', ":call CocAction('format')<CR>", { desc = 'Coc format' }) -- vscode format call...can this handle selection only?
    -- TODO how do i get coc-format-selection to work? in visual mode or?

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



    -- TODO revisit autoclose, try https://github.com/windwp/nvim-autopairs (uses treesitter, IIUC)
    -- -- https://github.com/m4xshen/autoclose.nvim
    -- use 'm4xshen/autoclose.nvim' -- auto close brackets, quotes, etc
    -- require('autoclose').setup({
    --   -- TODO how do I feel about this and copilot coexisting? seem to work ok, but will closing it out ever be an issue for suggestions
    --   -- TODO review keymaps for conflicts with coc/copilot/etc
    --   filetypes = { 'lua', 'python', 'javascript', 'typescript', 'c', 'cpp', 'rust', 'go', 'html', 'css', 'json', 'yaml', 'markdown' },
    --   ignored_next_char = "[%w%.]", -- ignore if next char is a word or period
    --
    --   -- FOOO isn't there a global option to stop it in command mode?
    --   -- ' disable_command_mode = true, -- disable in command line mode AND search /, often I want to search for one " or [[ and dont want them closed
    --
    -- })

    -- TODO paste with indent?

    -- use { 'wikitopian/hardmode' } -- disable arrow keys in normal mode (force hjkl)
    --
    -- force myself to learn hjkl to move up/down/left/right at least in normal mode?
    vim.keymap.set('n', '<up>', '')    -- disable up arrow
    vim.keymap.set('n', '<down>', '')  -- disable down arrow
    vim.keymap.set('n', '<left>', '')  -- disable left arrow
    vim.keymap.set('n', '<right>', '') -- disable right arrow

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

            }
        }
    })

    local builtin = require('telescope.builtin')
    --
    vim.cmd("let g:mapleader = ' '")                                                   -- default is '\' which is a bit awkward to reach, gotta take right hand off homerow
    --
    vim.keymap.set('n', '<leader>ft', builtin.builtin, { desc = 'Telescope Builtin' }) -- list pickers, select one opens it (like if :Telescope<CR>), shows keymaps too
    --
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
    -- TODO habituate Ctrl+V (open vertical split diff!)
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' }) -- proj search
    -- PRN ag? https://github.com/kelly-lin/telescope-ag  (extension  to telescope) => others https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })     -- leave as fb b/c over time I suspect I'll make more use of buffers?
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' }) -- awesome
    vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = 'Telescope commands' })
    vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = 'Telescope old files' })
    vim.keymap.set('n', '<leader>fv', builtin.vim_options, { desc = 'Telescope vim options' })
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope vim options' })
    --
    -- git related:
    vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Telescope git status' })     -- *** OMFG I am in ❤️ ... omg such a great way to do git status, side by side + search files and wow, dont need to leave my editor... wow
    vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = 'Telescope git commits' })   -- Ctrl+V sidebyside diff (:q closes), <CR> checkout, Ctrl+X horiz diff
    vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Telescope git branches' }) -- nice way to view, not sure I would use often
    --   pickers: https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#pickers
    --
    -- EXTENSIONS:
    use 'nvim-tree/nvim-web-devicons' -- icons to the right of find_files
    --
    use 'xiyaowong/telescope-emoji.nvim'
    require("telescope").load_extension("emoji")
    vim.keymap.set('n', '<leader>fe', ":Telescope emoji<CR>")
    --
    use 'catgoose/telescope-helpgrep.nvim'
    vim.keymap.set('n', '<leader>fgh', ":Telescope helpgrep<CR>", { desc = 'Telescope helpgrep' })
    --
    use 'https://github.com/nvim-telescope/telescope-file-browser.nvim'
    require("telescope").load_extension "file_browser"               -- this is why setting PWD matters when launching vim, at least for repo type projects, like w/ vscode
    vim.keymap.set('n', '<leader>br', ":Telescope file_browser<CR>") -- PRN shift+cmd+e would rock, can I get cmd to work in terminal w/ iTerm2?, I suspect iterm is always gonna snipe it
    --
    -- frecency on all pickers:
    -- use 'prochri/telescope-all-recent.nvim'
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





    -- TODO can I map [shift]+ctrl+tab to move forward/backward through files to edit? (like in vscode)
    --    edit #

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


    -- highlight just word under cursor:
    use "RRethy/vim-illuminate" -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column
    --    sadly, not the current selection (https://github.com/RRethy/vim-illuminate/issues/196), I should write this plugin
    --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
    --    customizing:
    --      hi def IlluminatedWordText gui=underline
    --      hi def IlluminatedWordRead gui=underline
    --      hi def IlluminatedWordWrite gui=underline
    --
    -- highlight selections like vscode:
    --     TODO TRY THIS...
    --      use "aaron-p1/match-visual.nvim" -- this one seems to do what I want, but I need to test it out


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

-- *** searching
vim.o.ignorecase = true -- ignore case when searching

-- FYI has('mouse') => nvi which is very close to what I had in vim ('a') ... only change if issue arises

--" Uncomment the following to have Vim jump to the last position when reopening a file
vim.cmd([[
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
]])
-- TODO how does neovim not have this by default?

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

    " *** misc key maps
    " ctrl+d to quit (in select situations) ... is this really a good idea?
    :nnoremap <C-d> :quit<CR>

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

    " Automatically save session when leaving Vim
    autocmd VimLeavePre * if (isdirectory(".git") || filereadable(".git")) | mksession! session.vim | endif

    " Automatically load session when opening Vim in a Git repository
    autocmd VimEnter * if filereadable("session.vim") | source session.vim | endif

    " highlighting doesn't work on first load of session (until e! or run filetype detect)
    autocmd SessionLoadPost * silent! filetype detect
]]
