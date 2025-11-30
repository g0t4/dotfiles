[
  (message (header_user)) @harmony_message_user
  (message (header_developer)) @harmony_message_developer
  (message (header_system)) @harmony_message_system
  (message header:(header_tool_result)) @harmony_message_tool_result
]
[
  (message header:(header_assistant_analysis)) @harmony_message_assistant_analysis
  (message header:(header_assistant_commentary)) @harmony_message_assistant_commentary
  (message header:(header_assistant_final)) @harmony_message_assistant_final
]
[
  (model_response_to_start_assistant_prefill) @harmony_message_prefill
]
[
   (start_token) @harmony_start_token
]

;
; ; just for fun, flag warning nodes to highlight as error text in neovim:
; [
;   ; flag possible issues, text fields that appear not to be JSON... though this is just illustrative
;   (
;     ((text) @body)
;     (#not-match? @body "^[\\[{]")     ; does NOT start with { or [
;   ) @comment.error
; ]
