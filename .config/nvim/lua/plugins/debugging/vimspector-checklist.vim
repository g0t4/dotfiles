" copied from: https://raw.githubusercontent.com/puremourning/vimspector/refs/heads/master/support/custom_ui_vimrc
" !!! use this as a checklist, delete items once ported or if don't wanna use

" setup boilerplate to make this file usable with vim -Nu <this file> {{{
scriptencoding utf-8
execute 'source' expand( '<sfile>:p:h' ) . '/minimal_vimrc'
set noequalalways
let mapleader = ','
let maplocalleader = "\<Space>"
let s:custom_process_picker = expand( '<sfile>:p:h' ) . '/vimspector_process_list/vimspector_process_list'
" }}}

" Custom Layout {{{

function! s:CustomiseUI()
  let wins = g:vimspector_session_windows
  " i.e.:
  "   {'stack_trace': 1064, 'output': 1067, 'watches': 1065, 'variables': 1066, 'code': 1063, 'eval': v:null, 'mode': 'horizontal', 'breakpoints': v:null, 'tabpage': 2}

  " Close the Variables window
  if has( 'nvim' )
    " No win_execute in neovim
    call win_gotoid( wins.variables )
    quit
  else
    call win_execute( wins.variables, 'q' )
  endif

  " Put the stack trace at the top of the "left bar" (rotate)
  call win_gotoid( wins.stack_trace )
  wincmd r

  " Make the left column at least 70 chars
  70wincmd |

  " Make the code window at least 80 chars
  call win_gotoid( wins.code )
  80wincmd |

  " Make the output window 10 lines high and right at the top of the screen
  call win_gotoid( wins.output )
  10wincmd _
  wincmd K

  " Enable keyboard-hover for vars and watches
  call win_gotoid( g:vimspector_session_windows.variables )
  nmap <silent> <buffer> <LocalLeader>di <Plug>VimspectorBalloonEval

  call win_gotoid( g:vimspector_session_windows.watches )
  nmap <silent> <buffer> <LocalLeader>di <Plug>VimspectorBalloonEval
endfunction

function s:SetUpTerminal()
  if !has_key( g:vimspector_session_windows, 'terminal' )
    " There's a neovim bug which means that this doesn't work in neovim
    return
  endif
  let terminal_win = g:vimspector_session_windows.terminal

  " Make the terminal window at most 80 columns wide, ensuring there is enough
  " sapce for our code window (80 columns) and the left bar (70 columns)

  " Padding is 2 for the 2 vertical split markers and 2 for the sign column in
  " the code window.
  let left_bar = 70
  let code = 80
  let padding = 4
  let cols = max( [ min( [ &columns - left_bar - code - padding, 80 ] ), 10 ] )
  call win_gotoid( terminal_win )
  execute string(cols) . 'wincmd |'
endfunction

function! s:CustomiseWinBar()
    call win_gotoid( g:vimspector_session_windows.code)
    aunmenu WinBar
    nnoremenu WinBar.▷\ ᶠ⁵ :call vimspector#Continue()<CR>
    nnoremenu WinBar.↷\ ᶠ¹⁰ :call vimspector#StepOver()<CR>
    nnoremenu WinBar.↓\ ᶠ¹¹ :call vimspector#StepInto()<CR>
    nnoremenu WinBar.↑\ ˢᶠ¹¹ :call vimspector#StepOut()<CR>
    nnoremenu WinBar.❘❘\ ᶠ⁶ :call vimspector#Pause()<CR>
    nnoremenu WinBar.□\ ˢᶠ⁵ :call vimspector#Stop()<CR>
    nnoremenu WinBar.⟲\ ᶜˢᶠ⁵ :call vimspector#Restart()<CR>
    nnoremenu WinBar.✕\ ᶠ⁸ :call vimspector#Reset()<CR>
endfunction

augroup TestUICustomistaion
  autocmd!
  autocmd User VimspectorUICreated call s:CustomiseUI()
  autocmd User VimspectorTerminalOpened call s:SetUpTerminal()
  autocmd User VimspectorUICreated call s:CustomiseWinBar()
augroup END

" }}}

" Custom sign priority {{{

let g:vimspector_sign_priority = {
  \    'vimspectorBP':         3,
  \    'vimspectorBPCond':     2,
  \    'vimspectorBPDisabled': 1,
  \    'vimspectorPC':         999,
  \ }

" }}}

" Custom process picker {{{

function! CustomPickProcess( ... ) abort
  let ps = s:custom_process_picker
  " a:0 is number of args
  " a:1 is the optional binary name
  if a:0 > 0
    let ps .= ' ^' . a:1 . '$'
  endif

  " You should probably do something better than this...
  echo system( ps )
  let pid = input( 'Enter PID: ' )

  if empty( pid )
    return 0
  endif
  return str2nr( pid )
endfunction


let g:vimspector_custom_process_picker_func = 'CustomPickProcess'

" }}}

" vim: foldmethod=marker
