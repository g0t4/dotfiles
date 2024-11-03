
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

