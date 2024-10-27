; extends
[
  ; must put most specific first, somehow that dictates which matching hlgroup wins if multiple attached... not sure I can do ! not in treesitter matches so yeah I have to overlap
  (comment) @comment_todo_bang (#match? @comment_todo_bang "TODO!")
  (comment) @comment_todo (#match? @comment_todo "TODO[^!]")
]
[
 ; todo would it make sense to make each language specific? so I put -- ihn ... I'd prefer copy pasta this file and have a global catchall regex on front to match whatever comment start there is ... why is this not matching comment contents? is there a way to do that?
  (comment) @comment_asterisks (#match? @comment_asterisks "^(--|\") \\*\\*\\*[^!]")
  (comment) @comment_asterisks_bang (#match? @comment_asterisks_bang "^(--|\") \\*\\*\\*!")
]
[
  ; not match start only:
  (comment) @comment_prn_bang (#match? @comment_prn_bang "(PRN|FYI)!")
  (comment) @comment_prn (#match? @comment_prn "(PRN|FYI)[^!]")

  ; FYI if I wanna limit to start of comment:
  ;(comment) @comment_prn_bang (#match? @comment_prn_bang "^(--|\") (PRN|FYI)!")
  ;(comment) @comment_prn (#match? @comment_prn "^(--|\") (PRN|FYI)")
]
[
  ; !!! => comment_triple_bang
  (comment) @comment_triple_bang (#match? @comment_triple_bang "^(--|\") !!!")
  ; gotta use start for ! single bang... else matches my others, though maybe I can change hl group orders to fix that?
  (comment) @comment_single_bang (#match? @comment_single_bang "^(--|\") ![^!]") ; -- REDO others like this so not double labeling when not suppposed to
]
[
  ; ???+ => comment_triple_question
  (comment) @comment_triple_question (#match? @comment_triple_question "^(--|\") \\?\\?\\?+")
  ; ?|?? => comment_single_question (\\? == ?) and \\?? means optional ? (0 or 1)
  (comment) @comment_single_question (#match? @comment_single_question "^(--|\") \\?\\??[^\\?]")
]

