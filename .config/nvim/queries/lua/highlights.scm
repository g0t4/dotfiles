; extends
;
; TODO consider switching lua to shared highlights.scm (inherit from it too?)
[
  (comment) @comment_todo_bang (#match? @comment_todo_bang "TODO!") ; TODO! foo
  (comment) @comment_todo (#match? @comment_todo "TODO[^!]*") ; TODO foo
]
[
  (comment) @comment_asterisks_bang (#match? @comment_asterisks_bang "\\s*\\*\\*\\*!") ; ***! test
  (comment) @comment_asterisks (#match? @comment_asterisks "\\s*\\*+[^!]") ; *** w/o !
]
[
  (comment) @comment_prn_bang (#match? @comment_prn_bang "(PRN|FYI)!") ; PRN! foo
  (comment) @comment_prn (#match? @comment_prn "(PRN|FYI)[^!]") ; PRN foo
]
[
  ; !!! => comment_triple_bang
  (comment) @comment_triple_bang (#match? @comment_triple_bang "\\s!!!")
  (comment) @comment_single_bang (#match? @comment_single_bang "\\s![^!]")
]
[
  (comment) @comment_triple_question (#match? @comment_triple_question "\\s\\?\\?\\?+") ; ???+ foo
  (comment) @comment_single_question (#match? @comment_single_question "\\s\\?\\??[^\\?]"); ? foo
]
[
  (comment) @comment_cell_devider_bang (#match? @comment_cell_devider_bang "\\%\\%+\!") ;%%! foo cell
  (comment) @comment_cell_devider (#match? @comment_cell_devider "\\%\\%+") ;%% foo
]
