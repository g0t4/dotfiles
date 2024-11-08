#!/bin/bash

fibonacci() {
  local n=$1
  if (( n <= 0 )); then
    echo "Input should be a positive integer"
    return 1
  fi

  fib_sequence=(0 1)
  while (( ${#fib_sequence[@]} < n )); do
    next_number=$(( ${fib_sequence[-1]} + ${fib_sequence[-2]} ))
    fib_sequence+=($next_number)
  done

  echo "${fib_sequence[@]}"
}

f_n=$1
fibonacci $f_n
