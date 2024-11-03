
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
      \   ),
      \ ])
" FYI for cmdline_pipeline.fuzzy => 0=off,1=fuzzy,2=fuzzy w/o first char matching

