
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
