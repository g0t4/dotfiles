; target swift code in subprocess.run invocations
; subprocess.run([ "swift", "-e", r"""swift_expr"""])
;  TODO over time I can enhance this to cover more scenarios as I encounter them
;  TODO I should have an agent setup tests for this too, before expanding to other cases
((call
  function: (attribute
    object: (identifier) @_module
    attribute: (identifier) @_method)
  arguments: (argument_list
    (list
      (string
        (string_start)
        (string_content) @_command
        (string_end))
      (string
        (string_start)
        (string_content) @_arg1
        (string_end))
      (string
        (string_content) @injection.content))))
  (#eq? @_module "subprocess")
  (#eq? @_command "swift")
  (#eq? @_arg1 "-e")
  (#any-of? @_method "run" "call")
  (#set! injection.language "swift"))


