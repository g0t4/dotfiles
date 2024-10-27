; extends
[
  ; must put most specific first, somehow that dictates which matching hlgroup wins if multiple attached... not sure I can do ! not in treesitter matches so yeah I have to overlap
  (comment) @todo_bang_comment (#match? @todo_bang_comment "TODO!!!")
  (comment) @todo_comment (#match? @todo_comment "(TODO|PRN|FYI)")
]


