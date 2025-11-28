((message_content) @is_json (#match? @is_json "^\\{"))

; [
;   (start_token) @harmony_start_token
; ]
; [
;   (header_user) @harmony_user
;   (header_system) @harmony_system
;   (header_developer) @harmony_developer
; ]
[
  (message (header (header_user))) @harmony_message_user
  (message (header (header_developer))) @harmony_message_developer
  (message (header (header_system))) @harmony_message_system
  (message (header (header_tool_result))) @harmony_message_tool_result
]
[
  (message (header (header_assistant_analysis))) @harmony_message_assistant_analysis
  (message (header (header_assistant_commentary))) @harmony_message_assistant_commentary
  (message (header (header_assistant_final))) @harmony_message_assistant_final
]
