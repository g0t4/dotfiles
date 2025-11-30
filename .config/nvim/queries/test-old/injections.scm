; (file
;   (test
;     (output) @injection.content)
;   (#set! injection.language "query"))
; inject the input block using the captured language attribute

; ; Step 1 (working) - hardcode the language to harmony, baby steps:
; ((input) @injection.content
;   (#set! injection.language "harmony"))

; ; Step 2 - capture both language and content nodes - now, the end user can define the language in the test header!
;  i.e. :langauge(harmony) or :language(test)
(test
  (header
    (attributes
      (attribute
        language: (parameter) @injection.language))) ; @injection.language capture - the text of this captured node should be used (if available) as the injection language
  (input) @injection.content) ; @injection.content capture - captured node's contents are reparsed using the @injection.language!

; Step 3 - set query as the type for the output node
; TODO => set cst or query?
; BTW query => https://github.com/tree-sitter-grammars/tree-sitter-query
;     cst   => https://github.com/tree-sitter-grammars/tree-sitter-cst
;        tree-sitter parse --cst # get cst output
;
((output) @injection.content
  (#set! injection.language "query"))
