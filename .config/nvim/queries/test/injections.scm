;

; FYI to test this:
;   cd ~/repos/github/g0t4/tree-sitter-harmony/test/corpus/standalone
;   and run with a test case:
;     tree-sitter query ~/.config/nvim/queries/test/injections.scm user_message.test
;       BTW :cst test case in user_message.test

; FYI INPUT node language:
; * if :language(_lang_) is present, use it for INPUT node
; this uses two captures
; 1. capture header's language attribute's parameter's node text as @injection.language ==> i.e. harmony if :language(harmony)
; 2. input node is captured for @injection.content
(test
  (header
    (attributes
      (attribute
        language: (parameter) @injection.language))) ; @injection.language capture - the text of this captured node should be used (if available) as the injection language
  (input) @injection.content) ; @injection.content capture - captured node's contents are reparsed using the @injection.language!


; FYI OUTPUT node language
; * default output node to "query"(scm) language
;   https://github.com/tree-sitter-grammars/tree-sitter-query
;   this applies query language to output node (if present).. no other conditions
((output) @injection.content
  (#set! injection.language "query"))

; * if :cst attribute => set "cst" as hardcoded injection.language for output node (@injection.content)
;   https://github.com/tree-sitter-grammars/tree-sitter-cst
;   btw, b/c :cst is the attribute text, I cannot capture that directly with @injection.language b/c there's no :cst language
;   thus, I test for that and then use set to hardcode "cst" with injection.language
(test
  (header
    (attributes
     (attribute) @check_attr
     (#eq? @check_attr ":cst")
     (#set! injection.language "cst")))
  (output) @injection.content)

; FYI make sure to install cst/test/query languages
