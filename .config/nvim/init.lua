
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

    use 'Mofiqul/vscode.nvim' -- use "vscode" ... I added this in neovim, though my other theme is fine too it seems
    use 'tomasiser/vim-code-dark' -- use "codedark" from my vimrc

    use 'github/copilot.vim'

    use {
      'nvim-telescope/telescope.nvim', --tag = '0.1.8',
    -- or                            , branch = '0.1.x',
      requires = { {'nvim-lua/plenary.nvim'} }
    }
    -- TODO nvim-treesitter for telescope too

    -- TODO can I map [shift]+ctrl+tab to move forward/backward through files to edit? (like in vscode)

    -- TODO (vimrc plugins list):
    -- fuzzy find:
    --    https://github.com/liuchengxu/vim-clap
    --    Plugin 'ctrlpvim/ctrlp.vim' (from my vimrc)
    --
    -- gelguy/wilder.nvim  # compare to builtin picker and fuzzy finder instead?
    --    port config from vimrc if I use this
    --    can I setup wilder to not show unless I hit tab? I like how that works in nvim's menu picker OOB
    --
    -- Plugin 'ryanoasis/vim-devicons'
    --
    -- Plugin 'tpope/vim-commentary'  # switch to this if I don't like bundled comment in neovim
    --
    -- editorconfig? (bundled, right?)

    -- TODO treesitter setup (alternative to vim's syntax highlighting)
    --    BTW looks like lua is setup with tree sitter currently (hence why not output from :syntax in a lua file)
    --
--    use {
--        'nvim-treesitter/nvim-treesitter',
--        run = ':TSUpdate'
--    }
    -- TSModuleInfo shows nothing setup?! including nothing for lua?
    --
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
    -- TODO look into auto enable for certain filetypes (e.g. lua)... isn't this what ftplugin/lua.lua is doing?
    -- require'nvim-treesitter.configs'.setup {
    --   ensure_installed = "lua", -- Or other languages
    --   highlight = {
    --     enable = true, -- Enable Tree-sitter
    --   },
    -- }


end)

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
vim.o.wrap = false -- global nowrap, consider local settings for this instead
vim.o.textwidth = 0 -- disable globally, add back if I find myself missing it

-- *** tabs
-- I chose option 2 (always insert spaces, leave tabs as is with default tabstop=8)
vim.o.expandtab = true -- insert spaces for tabs
vim.o.softtabstop = 4 -- b/c expandtab is set, this is the width of an inserted tab in spaces
vim.o.shiftwidth = 4 -- shifting: << >>
-- vim.o.tabstop -- leave as is (8) so existing uses of tabs match width likely intended 

-- *** show whitespace
vim.opt.listchars = {tab='→ ',trail='·',space='⋅'} -- FYI also `eol:$`
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
]]--

vim.cmd([[
    " TODO fix when close the original file doesn't show
    command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
]])   

-- *** Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file 
vim.cmd("nnoremap <c-s> :w<CR>")
vim.cmd("vnoremap <c-s> <Esc><c-s>gv") -- esc=>normal mode => save => reselect visual mode, not working... figure out later
vim.cmd("inoremap <c-s> <c-o><c-s>")


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


---*** FIX delete in insert mode for neovim, have it actually delete the next char just like vim
vim.cmd([[

    " *** misc key maps 
    " ctrl+d to quit (in select situations) ... is this really a good idea? 
    :nnoremap <C-d> :quit<CR>

    
        
    " copilot overrides
    :imap <C-M-[> <Plug>(copilot-previous)
    :imap <C-M-]> <Plug>(copilot-next)


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


vim.cmd([[

    " ***  custom coloring (of comments)


    " IIGC... neovim highlighting is overriding this somehow... I need my guifg to take precedence...

    " TODO port my highlight rules
    " FYI do not experiment with *** matching as one mistake in the regex (not escaping) can mess up what is going on, best to learn how these work with a diff rule
    " autocmd FileType * hi CommentAsterisks guifg='#ff00c3'
    " autocmd FileType * syn match CommentAsterisks "#.*\*\*\s.*$" 
    " autocmd FileType *  defers running to apply to all file types (IIUC)
    "
    " set notermguicolors # uses ctermfg/bg
    "    wheras termguicolors uses guifg/bg
    "
    "   !!!! WHY IS fg ignored both ctermfg/bg BUT cterm (bold) works, and bg works???
    "   FURTHERMORE... `:highlight` shows my colors correctly  (scroll to bottom, very end to see them)
    "
    " I can redefine the color for Comment and new color is used: or if cleared then some other color takes over
    " :highlight clear Comment
    " :highlight Comment guifg='#27AE60'  " Ok I can change the fg color here! wth... but somehow this controls the final value 
    " 
    " !!! is this smth to do with treesitter or other syntax mechanism? if I run  syntax on this lua file only my syntax items are defined... as expected and their colors (even fg) are correct but then they dont render that way for FG (only BG does) here
    
    command CheckSyntaxIDs :echo synIDattr(synID(line('.'), col('.'), 1), 'name') . ' -> ' . synIDattr(synID(line('.'), col('.'), 0), 'name')
    
    "source ~/.config/nvim/highlights.vim



]])

-- vim.api.nvim_set_hl(0, "vimAutoCmd",{ fg = "red", bg = "red"})

-- TODO
-- load wilder.vim:
-- vim.cmd('source /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/nvim/todo_vimrc.vim')

