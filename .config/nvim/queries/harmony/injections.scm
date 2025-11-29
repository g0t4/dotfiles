; (
;  (
;   (text) @injection.content
;   (#match? @injection.content "^\\{")
;  )
;  (#set! injection.language "json")
; )

; if <|constrain|>json => assume json
(
 ; match the shape of nodes:
 (message
   header: (header_assistant_commentary
             format: (text) @theformat ) ; tag the nodes to constrain
   contents: (text) @injection.content )
 ; now, apply constraints:
 (#match? @theformat "json")
 ; PRN check for { at start of text too?
 (#set! injection.language "json")
)
; if tool result's contents (text) field then assume JSON
(
 (message
   header: (header_tool_result)
   contents: (text) @injection.content
 )
 ; PRN check for { at start of text too?
 (#set! injection.language "json")
)


