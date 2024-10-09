" *** VUNDLE SETUP
set nocompatible " must come first as it affects other settings
filetype off " vundle required
"
" Reminder, to install/update vundle:
"    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
"
" add vundle to runtime path
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim' " self-managed, required

" Plugin 'neoclide/coc.nvim', {'branch': 'release'}
"    TODO can I use copilot via coc?

Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'github/copilot.vim'

" wilder and company:
" let g:python3_host_prog = expand('~/repos/wes-config/wes-bootstrap/subs/dotfiles/.venv/bin/python3')
"    this seems specific to nvim or smth that nvim has OOB that vim doesn't
" - after that fuzzy search and other python features worked in wilder
"   pip3 install --break-system-packages --user pynvim
"
" FYI inspect python env used:
" execute 'py3 import sys; print(sys.path)'
" :py3 import sys; print(sys.path)
"    :py3 for p in sys.path:  print(p)  # one per line 
"     - interestingly, it doesn't include the path to my venv like it would if
"       you run this inside the venv outside of vim, so its as if its overriding
"       the site path or otherwise ignoring my venv? 
"     - also adds '_vim_path_' entry 
"       - does this mean I can install modules into a vim runtime dir? or?
"       - here is code that adds this:
"         https://github.com/vim/vim/blob/700cf8cfa1e926e2ba676203b3ad90c2c2083f1d/src/if_py_both.h#L24-L25
" https://github.com/roxma/vim-hug-neovim-rpc?tab=readme-ov-file#requirements
" - FYI this is where I stumbled on the --user site suggestion, though it also
" - seems to recommend using a venv or not --user site in other spots?
"
" :py3 import pip; pip.main(['install', '--user', 'pynvim'])
"    either package: pynvim|neovim
"
Plugin 'gelguy/wilder.nvim'
Plugin 'ryanoasis/vim-devicons'
if !has('nvim')
    " let $NVIM_PYTHON_LOG_FILE="/tmp/nvim_log"
    " let $NVIM_PYTHON_LOG_LEVEL="DEBUG"
    Plugin 'roxma/nvim-yarp'
    Plugin 'roxma/vim-hug-neovim-rpc'
endif

" TODO which of these do I still want to use?
" Plugin 'altercation/vim-colors-solarized'
" Plugin 'godlygeek/tabular'
" Plugin 'plasticboy/vim-markdown'
" Plugin 'christoomey/vim-titlecase'
" Plugin 'tpope/vim-fugitive'
" 

" color scheme research
" Plugin 'flazz/vim-colorschemes'
Plugin 'tomasiser/vim-code-dark'

" comments (bring back b/c apparently comment.vim from vim-runtime isn't in debian package for vim-runtime so... ugh
"   AND I noticed bundled has very few key bindings and extras like... no \cA \ci to append/invert comments
Plugin 'tpope/vim-commentary' " motions compat (gcc (current line), gc<motion>
" alt => also uses gc https://vimawesome.com/plugin/tcomment
" Plugin 'preservim/nerdcommenter' " not compat with motions https://vimawesome.com/plugin/the-nerd-commenter, [count]<leader>cc  => \cc or 5\cc  ... \cu (uncomment)
" \cA => append comment to line
" \ci => invert each line
" TODO review vim-commentary bindings (esp optional) again
"

call vundle#end()
"
" FYI:
" :PluginList
" :PluginInstall - run when change list above, or first time setup vim
" :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to
" see :h vundle for more details or wiki for FAQ
" *** VUNDLE END



" plugins from vim's builtin package manager
" packadd editorconfig " TODO consider, this is also bundled



" add Ctrl+\ to toggle too (think Cmd+\ in zed/vscode)
nnoremap <C-\> :Commentary<CR>

" *** shortmess settings, for status line (keep compact so can fit more info)
" default is "filnxtToOS"
set shortmess+=A " don't give ATTENTION messages if already open in another instance (swap file detected)
set shortmess+=I " don't give intro message (if no file passed in)
set shortmess-=S " remove S so see search count and W for wrapped indicator


set history=999		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set guifont=SauceCodePro\ Nerd\ Font\ Mono:h16
set nowrap " wrapping is annoying, though maybe it should be

" In many terminal emulators the mouse works just fine, thus enable it.
" If you have trouble copying text in vim with iterm2, use alt key to select
" without changing vim selection and mode
if has('mouse')
  set mouse=a
endif


" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has('gui_running')
  " DOES THIS EVEN WORK, is # supposed to be " for a comment:
  syntax enable #enable syntax (doesn't override settings like syntax on does) 
  set hlsearch
  "set background=light
  "colorscheme solarized
endif

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(':DiffOrig')
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" recognize .md files as markdown
au BufRead,BufNewFile *.md set filetype=markdown

" Uncomment the following to have Vim jump to the last position when reopening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" *** tabs *** see `:help tabstop` for intended ways to use tabs in vim (5 primary ways)
" I chose option 2 (always insert spaces, leave tabs as is with default tabstop=8)
    set expandtab " insert tabs as spaces
    set softtabstop=4 " b/c expandtab is set, this is the width of an inserted tab in spaces
    set shiftwidth=4 " when shifting use this as the width << and >>
    " set tabstop=8 (default) " leave as is so existing tabs are shown with default (as many use, esp mix tabs/spaces peeps)
" *** showing whitespace
    set listchars=tab:→\ ,trail:·,space:⋅ " FYI also `eol:$` can be useful, '\ ' escapes using a space for tab past first char
    command! ToggleShowWhitespace if &list | set nolist | else | set list | endif
" *** review `autoindent`/`smartindent`/`cindent` and `smarttab` settings, I think I am fine as is but I should check
    filetype plugin indent on " this is controlling indent on new lines for now and seems fine so leave it as is 
    set backspace=indent,start,eol " allow backspacing over everything in insert mode, including indent from autoindent, eol thru start of insert
" *** line width:
set textwidth=200


" work with OSX clipboard for yank/cut/paste
set clipboard=unnamed

" SHORTCUTS 
" Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file 
" in normal mode, write current buffer
nmap <c-s> :w<CR>
" in visual mode, escape to normal mode, trigger <c-s>, restore selection (gv)
vmap <c-s> <Esc><c-s>gv

" in insert mode, save but stay in insert mode, ctrl+o goes into normal mode
" without existing insert mode, so the <c-s> maps to the :w<CR> and then back
" to insert mode after 
" drawback - doesn't show that file saved b/c insert is in status
imap <c-s> <c-o><c-s>
"
" ctrl+w in command mode to quit
" nnoremap <c-w> <c-c>:q<CR>
" nnoremap <c-s-w> <c-c>:q!<CR>


"""""" SPELL CHECK SETTINGS (hacked together, should read up on this)
" :set spell spelllang=en_us
" can also clear style and use diff style which might make spelling useful to keep on
" :highlight clear SpellBad
" :highlight Spellbad cterm=underline gui=undercurl 
" FYI this helps show what is set and where:
"    :verbose highlight SpellBad
"

"""" highlight settings... separate of just spell check which uses highight of results of course
" :highlight clear Todo   " NOTE: TODO: are highlighted by default (clear that)
" :highlight clear warningmsg " dont put background on warnings either
" :highlight clear errormsg
" FYI
"   :help :highlight
"   :hi " list all highlight groups
"   :so $VIMRUNTIME/syntax/hitest.vim   " see current highlight groups
"   :help higlight-args
set termguicolors " enable 24-bit color support
" TODO port higlight style (or similar) from vscode
" TODO more colors from other styles (vscode/bat/iterm2/etc)
" 
" colorscheme visualstudio " light - from flazz/vim-colorschemes
" foo
" codedark-wes-mods (based on codedark.vim)
let g:codedark_transparent = 0 " 0/1   TODO what do I want? ?? fix iterm2 padding first? around vim window
" let g:codedark_modern = 1
" let g:codedark_conservative=0
" let g:codedark_italics=1 " i.e. for comments
colorscheme codedark-wes-mods " from tomasiser/vim-code-dark
" todo add color scheme to dotfiles repo and symlink it OR setup a repo and check it out as a vim plugin would work well too
"
set ignorecase " ignore case when searching
highlight Todo ctermfg=LightYellow guifg=#ffcc00
" FYI https://terminal.sexy (color designer)



" *** ASK OPENAI ABOUT VIM (duct tape)

function! TrimNullCharacters(input)
    " Replace null characters (\x00) with an empty string
    " was getting ^@ at end of command output w/ system call (below)
    return substitute(a:input, '\%x00', '', 'g')
endfunction

function! AskOpenAI()

    let l:cmdline = getcmdline()

    " todo this prompt here should be moved into vim.py script and combined with other system message instructs? specifically the don't include leading :? or should I allow leading: b/c it still works to have it
    let l:STDIN_text = ' env: vim command mode (return a valid command w/o the leading : ) \n question: ' . l:cmdline

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




" *** wilder config
"    https://vimawesome.com/plugin/wilder-nvim

call wilder#setup({'modes': [':', '/', '?']})

" FYI first func that responds terminates search, i.e.:   "   \     {ctx, x -> [x, 'foo', 'bar']},
call wilder#set_option('pipeline', [
      \   wilder#branch(
      \     [
      \       wilder#check({_, x -> empty(x)}),
      \       wilder#history(),
      \       wilder#result({
      \         'draw': [{_, x -> ' ' . x}],
      \       }),
      \     ],
      \     wilder#cmdline_pipeline({
      \       'language': 'python',
      \       'fuzzy': 1,
      \     }),
      \     wilder#python_search_pipeline({
      \       'pattern': wilder#python_fuzzy_pattern(),
      \       'sorter': wilder#python_difflib_sorter(),
      \       'engine': 're',
      \     }),
      \   ),
      \ ])
" FYI for cmdline_pipeline.fuzzy => 0=off,1=fuzzy,2=fuzzy w/o first char matching

" FYI quit/reopen vim when changing highlight parameters (i.e. ctermfg)
highlight MyWilderPopupmenu ctermfg=121 " seagreen color, based on MoreMsg highlight group builtin
highlight MyWilderPopupmenuSelected ctermbg=9 " red bg, based on DiffText builtin (FYI to test this search files and hit Tab to step through search results popup menu)
highlight MyWilderPopupmenuAccent cterm=bold ctermfg=0 " test by searching commands (prefix matches is accent color)
highlight MyWilderPopupmenuSelectedAccent cterm=bold ctermfg=0 ctermbg=9" test by search commmands (i.e. :w and tab to select and step through)
" :h popupmenu_renderer  => (highlights groups) => 
"   - default (default=PMenu), 
"   - selected (default=PmenuSel)
"   - error (default=ErrorMsg)
"   - accent (default=default + underline + bold)
"   - selected_accent (default=selected + underline + bold)
"   - empty_message (default=WarningMsg)
" 
" :h highlight-groups
" :h highlight   " list groups you can use

" use popup menu for everything (see _mux below for diff menu based on type)
call wilder#set_option('renderer', wilder#popupmenu_renderer({
      \ 'highlighter': wilder#basic_highlighter(),
      \ 'highlights': {
      \   'default': 'MyWilderPopupmenu',
      \   'selected': 'MyWilderPopupmenuSelected',
      \   'accent': 'MyWilderPopupmenuAccent',
      \   'selected_accent': 'MyWilderPopupmenuSelectedAccent',
      \ },
      \ 'left': [
      \   ' ', wilder#popupmenu_devicons(),
      \ ],
      \ 'right': [
      \   ' ', wilder#popupmenu_scrollbar(),
      \ ],
      \ }))


" example of using popup for commands, wildmenu (horizontal) for files
" let s:highlighters = [
"         \ wilder#pcre2_highlighter(),
"         \ wilder#basic_highlighter(),
"         \ ]
" call wilder#set_option('renderer', wilder#renderer_mux({
"       \ ':': wilder#popupmenu_renderer({
"       \   'left': [ ' ', wilder#popupmenu_devicons(), ],
"       \   'highlighter': s:highlighters,
"       \ }),
"       \ '/': wilder#wildmenu_renderer({
"       \   'left': [ ' ', wilder#popupmenu_devicons(), ],
"       \   'highlighter': s:highlighters,
"       \ }),
"       \ }))



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





" custom coloring (of comments)
" TODO port my highlight rules
" FYI do not experiment with *** matching as one mistake in the regex (not escaping) can mess up what is going on, best to learn how these work with a diff rule
" autocmd FileType * hi CommentAsterisks guifg='#ff00c3'
" autocmd FileType * syn match CommentAsterisks "#.*\*\*\s.*$" 
" autocmd FileType *  defers running to apply to all file types (IIUC)
"
" FYI matcher:
autocmd FileType * hi CommentFYI guifg='#27AE60'
" TODO /* should end on */ ... I need to learn more about nested syntax/highlights cuz I should be able to match on a subset of the comment rules for diff langauges,right?
autocmd FileType * syn match CommentFYI /\(#\|"\|\/\/\|\/\*\)\s*FYI\s.*/ " why can I not match on stuff just after the #... it's as if I cannot match on a subset of the comment and must match starting with the # at least and then with # at start I can avoid matching start of line but I cannot just have /FYI/ that won't match whereas /# FYI/ will match (and only the #+ part, not the start of line.. why is this discrepency in subset matching)?
" FYI! matcher (bold, inverted):
autocmd FileType * hi CommentFYIBang guibg='#27AE60' guifg='#1f1f1f' cterm=bold " why doesn't gui=bold work? 
autocmd FileType * syn match CommentFYIBang /\(#\|"\|\/\/\|\/\*\)\s*FYI\!\s.*/
"
" TODO disable the builtin Todo styles altogether (highlight group)
" TODO matcher:
autocmd FileType * hi CommentTODO guifg='#ffcc00'
autocmd FileType * syn match CommentTODO /\(#\|"\|\/\/\|\/\*\)\s*TODO\s.*/
" TODO! matcher (bold, inverted):
autocmd FileType * hi CommentTODOBang guibg='#ffcc00' guifg='#1f1f1f' cterm=bold
autocmd FileType * syn match CommentTODOBang /\(#\|"\|\/\/\|\/\*\)\s*TODO\!\s.*/
" ! matcher:
autocmd FileType * hi CommentSingleBang guifg='#cc0000'
autocmd FileType * syn match CommentSingleBang /\(#\|"\|\/\/\|\/\*\)\s*\!\s.*/
" !!! matcher:
autocmd FileType * hi CommentTripleBang guibg='#cc0000' guifg='#ffffff' cterm=bold
autocmd FileType * syn match CommentTripleBang /\(#\|"\|\/\/\|\/\*\)\s*\!\!\!\s.*/
" ? matcher:
" ?? matcher:
autocmd FileType * hi CommentSingleQuestion guifg='#3498DB'
autocmd FileType * syn match CommentSingleQuestion /\(#\|"\|\/\/\|\/\*\)\s*\(?\|??\)\s.*/ " using () to match ? or ?? only... ok to match more but just lets be specific so order isn't as important 
" ??? matcher:
" ???? matcher:
autocmd FileType * hi CommentTripleQuestion guibg='#3498DB' guifg='#1f1f1f' cterm=bold
autocmd FileType * syn match CommentTripleQuestion /\(#\|"\|\/\/\|\/\*\)\s*????*\s.*/ " shouldn't ? need to be escaped?! this breaks when I do that
" * matcher:
" ** matcher:
autocmd FileType * hi CommentSingleAsterisk guifg='#ff00c3'
autocmd FileType * syn match CommentSingleAsterisk /\(#\|"\|\/\/\|\/\*\)\s*\(\*\|\*\*\)\s.*/ " using () to match ? or ?? only... ok to match more but just lets be specific so order isn't as important 
" *** matcher:
" **** matcher:
autocmd FileType * hi CommentTripleAsterisk guibg='#ff52d1' guifg='#1f1f1f' cterm=bold " FYI not same pink as foreground version (lightened up using alpha in vscode mapped to RGB for here)
autocmd FileType * syn match CommentTripleAsterisk /\(#\|"\|\/\/\|\/\*\)\s*\*\*\*\**\s.*/ " shouldn't ? need to be escaped?! this breaks when I do that


