; extends
;
; TODO need to not apply this to non-lua languages => update all symlinks to point at smth that is not lua :) and let lua symlink the highlights only and then add its own fold additions!

; * target local foo = [[ ]] in lua...
; test:
;   tree-sitter query .config/nvim/queries/lua/folds.scm .config/nvim/queries/lua/tests/literal.lua
local_declaration: (variable_declaration
  (assignment_statement
    (variable_list
      name: (identifier))
    (expression_list
      value: (string) @fold)))
; TODO need to check value is "[[" (not child) else this might fold other things I don't want folded

