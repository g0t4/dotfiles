" PRN matcher:
" FYI matcher:
autocmd FileType * hi CommentFYI guifg='#27AE60'
autocmd FileType * syn match CommentFYI /\(--\|#\|"\|\/\/\|\/\*\)\s*\(FYI\|PRN\)\s.*/ " TODO I don't stop on */ on end of multiline comments, perhaps I should be using a plugin for this :)
" PRN! matcher too:
" FYI! matcher (bold, inverted):
autocmd FileType * hi CommentFYIBang guibg='#27AE60' guifg='#1f1f1f' gui=bold " why doesn't gui=bold work? 
autocmd FileType * syn match CommentFYIBang /\(--\|#\|"\|\/\/\|\/\*\)\s*\(FYI\|PRN\)\!\s.*/

" TODO disable the builtin Todo styles altogether (highlight group)
" TODO matcher:
autocmd FileType * hi CommentTODO guifg='#ffcc00'
autocmd FileType * syn match CommentTODO /\(--\|#\|"\|\/\/\|\/\*\)\s*TODO\s.*/
" TODO! matcher (bold, inverted):
autocmd FileType * hi CommentTODOBang guibg='#ffcc00' guifg='#1f1f1f' gui=bold
autocmd FileType * syn match CommentTODOBang /\(--\|#\|"\|\/\/\|\/\*\)\s*TODO\!\s.*/


" ! matcher:
autocmd FileType * hi CommentSingleBang guifg='#cc0000'
autocmd FileType * syn match CommentSingleBang /\(--\|#\|"\|\/\/\|\/\*\)\s*\!\s.*/
" !!! matcher:
autocmd FileType * hi CommentTripleBang guibg='#cc0000' guifg='#ffffff' gui=bold
autocmd FileType * syn match CommentTripleBang /\(--\|#\|"\|\/\/\|\/\*\)\s*\!\!\!\s.*/


" ? matcher:
" ?? matcher:
autocmd FileType * hi CommentSingleQuestion guifg='#3498DB'
autocmd FileType * syn match CommentSingleQuestion /\(--\|#\|"\|\/\/\|\/\*\)\s*\(?\|??\)\s.*/ " using () to match ? or ?? only... ok to match more but just lets be specific so order isn't as important 
" ??? matcher:
" ???? matcher:
autocmd FileType * hi CommentTripleQuestion guibg='#3498DB' guifg='#1f1f1f' gui=bold
autocmd FileType * syn match CommentTripleQuestion /\(--\|#\|"\|\/\/\|\/\*\)\s*????*\s.*/ " shouldn't ? need to be escaped?! this breaks when I do that

" * matcher:
" ** matcher:
" *** matcher:
autocmd FileType * hi CommentSingleAsterisk guifg='#ff00c3'
autocmd FileType * syn match CommentSingleAsterisk /\(--\|#\|"\|\/\/\|\/\*\)\s*\*\**\s.*/ " using () to match ? or ?? only... ok to match more but just lets be specific so order isn't as important 
" ***! matcher:
autocmd FileType * hi CommentTripleAsterisk guibg='#ff52d1' guifg='#1f1f1f' gui=bold " FYI not same pink as foreground version (lightened up using alpha in vscode mapped to RGB for here)
autocmd FileType * syn match CommentTripleAsterisk /\(--\|#\|"\|\/\/\|\/\*\)\s*\*\*\*\!\s.*/ " shouldn't ? need to be escaped?! this breaks when I do that


" use to test when this is applied/loaded
" autocmd FileType * echo "FileType detected"
