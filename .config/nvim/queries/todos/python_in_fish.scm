;[
; ok goal is to find python code strings in my fish shell scripts...
; i.e.:
; python -c "print('hello')"
;
; and then highlight them as python

;; :InspectTree output:
;    (command ; [1490, 4] - [1500, 1]
;      name: (word) ; [1490, 4] - [1490, 11]
;      argument: (word) ; [1490, 12] - [1490, 14]
;      argument: (double_quote_string ; [1490, 15] - [1500, 1]

(command
  name: (word) @python_name
  argument: (double_quote_string) @python
  (#any-of? @python_name "python" "python3")

)

;]

