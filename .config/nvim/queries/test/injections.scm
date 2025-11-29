; (file
;   (test
;     (output) @injection.content)
;   (#set! injection.language "query"))
; inject the input block using the captured language attribute
; ((test
;   (header
;     (attributes
;       (attribute
;         (parameter) @corpus.lang)))
;   (input) @corpus.input)
;   (#set! injection.language @corpus.lang)
;   (#set! injection.include-children "true"))
; ((test
;   (header
;     (attributes
;       (attribute
;         language: (parameter) @corpus.lang)))
; (#set! injection.language @corpus.lang))

; hardcode the language to harmony, baby steps:
((input) @injection.content
  (#set! injection.language "harmony"))
