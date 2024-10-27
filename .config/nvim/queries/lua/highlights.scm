; extends
[
  ; must put most specific first, somehow that dictates which matching hlgroup wins if multiple attached... not sure I can do ! not in treesitter matches so yeah I have to overlap
  (comment) @todo_bang_comment (#match? @todo_bang_comment "TODO!!!")
  (comment) @todo_comment (#match? @todo_comment "(TODO|PRN|FYI)")
]
[
 ; todo would it make sense to make each language specific? so I put -- ihn ... I'd prefer copy pasta this file and have a global catchall regex on front to match whatever comment start there is ... why is this not matching comment contents? is there a way to do that?
  (comment) @comment_asterisks (#match? @comment_asterisks "-- \\*\\*\\*")
]


