; extends
; inherits: shared




; TODO REMOVE THE FOLLOWING LATER... conceal examples:
; (expression_statement (call) @conceal  (#set! conceal ""))
;
; hide entire line w/ conceal_lines=
; (([ "(" ")" ]) @myconceal (#set! conceal_lines ""))
; hide just ONE CHAR w/ conceal=
; (([ "(" ")" ]) @myconceal (#set! conceal "|"))
; set conceallevel=0 ; disabled conceal
; set conceallevel=1 ; replace with single char (if "" no replace char => uses listchars)
; set conceallevel=2 ; replace with single char (if "" no replace char => hide)
; set conceallevel=3 ; completely hide all
;
; only first char used:
; ("!=" @ne_operator (#set! conceal "≠foo"))
; ("!=" @ne_operator (#set! conceal_lines ""))

