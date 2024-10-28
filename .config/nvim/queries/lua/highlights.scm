; extends
;
; TODO map to more languages, add prefixes for various comment types, almost want a script to generate this file per language actually :) then not even need the wild regex?
;
; #match? docs:   https://neovim.io/doc/user/treesitter.html#treesitter-predicate-vim-match%3F
;    is match nvim specific?
;    regex param links to: https://neovim.io/doc/user/pattern.html#regexp
[
  ; AFAICT first capture group wins out (for whatever its corresponding hlgroup defines and only subsequent capture groups can impact attrs not set by previous hlgroup of prev capture group)
  ; must put most specific first, somehow that dictates which matching hlgroup wins if multiple attached... not sure I can do ! not in treesitter matches so yeah I have to overlap
  ;   THIS must have smth to do with issues I had with the syntax matches ... it seemed like first hl-group applied wins (for the attrs it sets and so subsequent can apply a diff characteristic (fg/bg) but not override prev capture groups or smth)...
  ;   hl group ordering doesn't matter here, if I fliop bang after non-bang, then the fg comes from the non-bang even on the bangs... flip it and then the bang wins b/c it sets both fg and bg... and I tried flipping hlgroup definitioon ordering and that did not matter
  (comment) @comment_todo_bang (#match? @comment_todo_bang "TODO!")
  (comment) @comment_todo (#match? @comment_todo "TODO[^!]")
]
[
 ; todo would it make sense to make each language specific? so I put -- ihn ... I'd prefer copy pasta this file and have a global catchall regex on front to match whatever comment start there is ... why is this not matching comment contents? is there a way to do that?
  (comment) @comment_asterisks_bang (#match? @comment_asterisks_bang "^(--|\")\\s\\*\\*\\*!")
  (comment) @comment_asterisks (#match? @comment_asterisks "^(--|\")\\s\\*+[^!]") ; TODO fix matching ***! too... damn weird regex... are these not greedy?
]
[
  ; not match start only:
  (comment) @comment_prn_bang (#match? @comment_prn_bang "(PRN|FYI)!")
  (comment) @comment_prn (#match? @comment_prn "(PRN|FYI)[^!]")

  ; FYI if I wanna limit to start of comment:
  ;(comment) @comment_prn_bang (#match? @comment_prn_bang "^(--|\")\\s(PRN|FYI)!")
  ;(comment) @comment_prn (#match? @comment_prn "^(--|\")\\s(PRN|FYI)")
]
[
  ; !!! => comment_triple_bang
  (comment) @comment_triple_bang (#match? @comment_triple_bang "^(--|\")\\s!!!")
  ; gotta use start for ! single bang... else matches my others, though maybe I can change hl group orders to fix that?
  (comment) @comment_single_bang (#match? @comment_single_bang "^(--|\")\\s![^!]") ; -- REDO others like this so not double labeling when not suppposed to
]
[
  ; ???+ => comment_triple_question
  (comment) @comment_triple_question (#match? @comment_triple_question "^(--|\")\\s\\?\\?\\?+")
  ; ?|?? => comment_single_question (\\? == ?) and \\?? means optional ? (0 or 1)
  (comment) @comment_single_question (#match? @comment_single_question "^(--|\")\\s\\?\\??[^\\?]")
]
