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

Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'github/copilot.vim'

" wilder and company:
" let g:python3_host_prog = expand('~/repos/wes-config/wes-bootstrap/subs/dotfiles/.venv/bin/python3')
" FYI had to add pynvim to my user site, even though I configured a venv...
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
" Plugin 'scrooloose/syntastic'
" Plugin 'altercation/vim-colors-solarized'
" Plugin 'godlygeek/tabular'
" Plugin 'plasticboy/vim-markdown'
" Plugin 'christoomey/vim-titlecase'
" Plugin 'tpope/vim-fugitive'
" 
" comments
Plugin 'tpope/vim-commentary' " motions compat (gcc (current line), gc<motion> 
" alt => also uses gc https://vimawesome.com/plugin/tcomment
" Plugin 'preservim/nerdcommenter' " not compat with motions https://vimawesome.com/plugin/the-nerd-commenter, [count]<leader>cc  => \cc or 5\cc  ... \cu (uncomment)
" \cA => append comment to line
" \ci => invert each line
"
call vundle#end()
filetype plugin indent on
"
" FYI:
" :PluginList
" :PluginInstall - run when change list above, or first time setup vim
" :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to
" see :h vundle for more details or wiki for FAQ
" *** VUNDLE END

set backspace=indent,eol,start " allow backspacing over everything in insert mode
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

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_yaml_checkers = 1 


" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  " DOES THIS EVEN WORK, is # supposed to be " for a comment:
  syntax enable #enable syntax (doesn't override settings like syntax on does) 
  set hlsearch
  "set background=light
  "colorscheme solarized
endif

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" recognize .md files as markdown
au BufRead,BufNewFile *.md set filetype=markdown

" show tabs as 4 spaces
set tabstop=4
" in insert mode, use spaces instead of tabs when typing tab key
set expandtab
" when shifting use this as the width << and >>
set shiftwidth=4

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

"""""" SPELL CHECK SETTINGS (hacked together, should read up on this)
" :set spell spelllang=en_us
" can also clear style and use diff style which might make spelling useful to keep on
" :highlight clear SpellBad
" :highlight Spellbad cterm=underline gui=undercurl 
" FYI this helps show what is set and where:
"    :verbose highlight SpellBad
"
"""" highlight settings... separate of just spell check which uses highight of results of course
:highlight clear Todo   " NOTE: TODO: are highlighted by default (clear that)
:highlight clear warningmsg " dont put background on warnings either
:highlight clear errormsg
" todo I think I need to learn who to use Syntastic? to fix some of these clashes
"  for now remove highlight on todos / notes b/c it changes background color and is way too noticeable
"    TODO find out what all I can set and adjust highlighting so I'm more likey to use vim


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
