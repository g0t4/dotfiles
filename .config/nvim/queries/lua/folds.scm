; extends
;
; TODO need to not apply this to non-lua languages => update all symlinks to point at smth that is not lua :) and let lua symlink the highlights only and then add its own fold additions!

; * target local foo = [[ ]] in lua...
; test:
;   tree-sitter query .config/nvim/queries/lua/folds.scm .config/nvim/queries/lua/tests/literal.lua
;
; 1. first attempt (works good too I think):
;
; local_declaration: (variable_declaration
;   (assignment_statement
;     (variable_list
;       name: (identifier))
;     (expression_list
;       value: (string) @fold)))
; ; TODO need to check value is "[[" (not child) else this might fold other things I don't want folded
;
; 2. more specific inside ( [[ ]] )... but general w.r.t. container this lives in (vs above)
; fold any multline string literal including the [[ ]] node
(string
  "[["
  (string_content)
  "]]") @fold

