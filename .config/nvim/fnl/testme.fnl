;(print "jerkwad")
(vim.print "ifoo")
(fn foo [] "this does your mother a favour" (print "foo"))
(foo)

(local config {
       :foo "bar"
       :boo "bam"
       :baz "bong"
})

(vim.print config)

(local types [
   "spicy"
   "hot"
   "sweet"
   "sour"
   "lame"
   ])

(each [k v (pairs config)]
  (vim.print k)
  (let [msg (.. (.. (.. "key: " k) " => value: ") v)]
    (vim.print msg)
    ))
