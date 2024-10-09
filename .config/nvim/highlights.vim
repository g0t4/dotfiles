" PRN matcher:
" FYI matcher:
autocmd FileType * hi CommentFYI guifg='#27AE60'
" TODO /* should end on */ ... I need to learn more about nested syntax/highlights cuz I should be able to match on a subset of the comment rules for diff langauges,right?
autocmd FileType * syn match CommentFYI /\(--\|#\|"\|\/\/\|\/\*\)\s*\(FYI\|PRN\)\s.*/ " why can I not match on stuff just after the #... it's as if I cannot match on a subset of the comment and must match starting with the # at least and then with # at start I can avoid matching start of line but I cannot just have /FYI/ that won't match whereas /# FYI/ will match (and only the #+ part, not the start of line.. why is this discrepency in subset matching)?
" PRN! matcher too:
" FYI! matcher (bold, inverted):
autocmd FileType * hi CommentFYIBang guibg='#27AE60' guifg='#1f1f1f' cterm=bold " why doesn't gui=bold work? 
autocmd FileType * syn match CommentFYIBang /\(--\|#\|"\|\/\/\|\/\*\)\s*\(FYI\|PRN\)\!\s.*/
"
" TODO disable the builtin Todo styles altogether (highlight group)
" TODO matcher:
autocmd FileType * hi CommentTODO guifg='#ffcc00'
autocmd FileType * syn match CommentTODO /\(--\|#\|"\|\/\/\|\/\*\)\s*TODO\s.*/
" TODO! matcher (bold, inverted):
autocmd FileType * hi CommentTODOBang guibg='#ffcc00' guifg='#1f1f1f' cterm=bold
autocmd FileType * syn match CommentTODOBang /\(--\|#\|"\|\/\/\|\/\*\)\s*TODO\!\s.*/
" ! matcher:
autocmd FileType * hi CommentSingleBang guifg='#cc0000'
autocmd FileType * syn match CommentSingleBang /\(--\|#\|"\|\/\/\|\/\*\)\s*\!\s.*/
" !!! matcher:
autocmd FileType * hi CommentTripleBang guibg='#cc0000' guifg='#ffffff' cterm=bold
autocmd FileType * syn match CommentTripleBang /\(--\|#\|"\|\/\/\|\/\*\)\s*\!\!\!\s.*/
" ? matcher:
" ?? matcher:
autocmd FileType * hi CommentSingleQuestion guifg='#3498DB'
autocmd FileType * syn match CommentSingleQuestion /\(--\|#\|"\|\/\/\|\/\*\)\s*\(?\|??\)\s.*/ " using () to match ? or ?? only... ok to match more but just lets be specific so order isn't as important 
" ??? matcher:
" ???? matcher:
autocmd FileType * hi CommentTripleQuestion guibg='#3498DB' guifg='#1f1f1f' cterm=bold
autocmd FileType * syn match CommentTripleQuestion /\(--\|#\|"\|\/\/\|\/\*\)\s*????*\s.*/ " shouldn't ? need to be escaped?! this breaks when I do that

autocmd FileType * echo "FileType detected"

" * matcher:



