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
" TODO which of these do I still want to use?
" Plugin 'scrooloose/syntastic'
" Plugin 'altercation/vim-colors-solarized'
" Plugin 'godlygeek/tabular'
" Plugin 'plasticboy/vim-markdown'
" Plugin 'christoomey/vim-titlecase'
" Plugin 'ctrlpvim/ctrlp.vim'
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


set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

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

