## dynamic scoping

- bash uses dynamic scoping
- caller's scope is visible to callee
  - think parent/child relationship
  - same is true all the way up the stack to the global scope
- parent passes all its variables as implicit parameters
    - part of me wants to say, you should still use explicit positional params
        - on the caller side makes it obvious what is passed
        - BUT, on the callee side you have to extract the values from $1, $2, etc
    - so, maybe just let the callee reach into the dynamic scope?!
        - add logic to warn if not defined (declare -p)?
