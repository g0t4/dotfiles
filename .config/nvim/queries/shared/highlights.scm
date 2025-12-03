;
; FYI https://github.com/nvim-treesitter/nvim-treesitter/tree/master/queries (use as a ref for building queries - has every language imaginable)
;
; #match? docs:   https://neovim.io/doc/user/treesitter.html#treesitter-predicate-vim-match%3F
;    is match nvim specific?
;    regex param links to: https://neovim.io/doc/user/pattern.html#regexp
[
  ; AFAICT first capture group wins out (for whatever its corresponding hlgroup defines and only subsequent capture groups can impact attrs not set by previous hlgroup of prev capture group)
  ; must put most specific first, somehow that dictates which matching hlgroup wins if multiple attached... not sure I can do ! not in treesitter matches so yeah I have to overlap
  ;   THIS must have smth to do with issues I had with the syntax matches ... it seemed like first hl-group applied wins (for the attrs it sets and so subsequent can apply a diff characteristic (fg/bg) but not override prev capture groups or smth)...
  ;   hl group ordering doesn't matter here, if I fliop bang after non-bang, then the fg comes from the non-bang even on the bangs... flip it and then the bang wins b/c it sets both fg and bg... and I tried flipping hlgroup definitioon ordering and that did not matter
  ; TODO - both FYI and TODO are not matching first comment in a file, has to be content before it... fix these to match on any comment in file like I do with others here
  (comment) @comment_todo_bang (#match? @comment_todo_bang "TODO!")
  (comment) @comment_todo (#match? @comment_todo "TODO[^!]*")
  ; FYI treesitter uses priority 100 (by default) for its extmarks (i.e. OOB @comment.bash)
  ;   convention wise, I want to use: 100=default (unset), 200=shared, 300+=specific to language
  (#set! priority 200)
  ; IIUC one of the above two wins and then the priority is set by this directive (after winner selected)
  ;   that said, I see many examples where it seems both win for the same node?! (i.i. triple asterisk with and w/o bang below
]
[
  (comment) @comment_asterisks_bang (#match? @comment_asterisks_bang "\\s*\\*\\*\\*!")  ; ***! test
  (comment) @comment_asterisks  (#match? @comment_asterisks "\\s*\\*+[^!]") ; *** w/o !
  (#set! priority 200)
  ; now this matches the entire line even if only in a secondary nested comment -- ** like this
  ; foo the bar * example (really shouldn't light up, I only want *** at start of comment
  ; foo the ; *** bar  (ok not to lightup)
  ; * example
  ; ** example
  ; *** example
  ; ***! example
]
[
  (comment) @comment_prn_bang (#match? @comment_prn_bang "(PRN|FYI)!")
  (comment) @comment_prn (#match? @comment_prn "(PRN|FYI)[^!]")
  (#set! priority 200)
]
[
  ; !!! => comment_triple_bang
  (comment) @comment_triple_bang (#match? @comment_triple_bang "\\s!!!")
  ; gotta use start for ! single bang... else matches my others, though maybe I can change hl group orders to fix that?
  (comment) @comment_single_bang (#match? @comment_single_bang "\\s![^!]") ; -- REDO others like this so not double labeling when not suppposed to
  (#set! priority 200)
]
[
  ; ???+ => comment_triple_question
  (comment) @comment_triple_question (#match? @comment_triple_question "\\s\\?\\?\\?+")
  ; ?|?? => comment_single_question (\\? == ?) and \\?? means optional ? (0 or 1)
  (comment) @comment_single_question (#match? @comment_single_question "\\s\\?\\??[^\\?]")
  (#set! priority 200)
]
[
  (comment) @comment_cell_devider_bang (#match? @comment_cell_devider_bang "\\%\\%+!") ;%%! cell devider highlight (for iron REPL "notebooks")
  (comment) @comment_cell_devider (#match? @comment_cell_devider "\\%\\%+") ;%% foo
  (#set! priority 200)
  ; regular comment (not underlined, nor bold)
]
