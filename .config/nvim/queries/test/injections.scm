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

; ; Step 1 (working) - hardcode the language to harmony, baby steps:
; ((input) @injection.content
;   (#set! injection.language "harmony"))

; ; Step 2 - use language attribute to inject input node's language
(test
  (header
    (attributes
      (attribute
        language: (parameter) @injection.language)))
  (input) @injection.content)
