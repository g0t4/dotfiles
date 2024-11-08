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
f_n=3
echo "# Expected: 0 1 1 Actual:"
actual_fib=$(fibonacci $f_n)
echo "Actual: ${actual_fib[@]}"

echo ""

f_n=4
echo "# Expected: 0 1 1 2 Actual:"
actual_fib=$(fibonacci $f_n)
echo "Actual: ${actual_fib[@]}"

echo ""

f_n=5
echo "# Expected: 0 1 1 2 3 Actual:"
actual_fib=$(fibonacci $f_n)
echo "Actual: ${actual_fib[@]}"

echo ""

f_n=7
echo ""
echo "# Expected: 0 1 1 2 3 5 8 Actual:"
actual_fib=$(fibonacci $f_n)
echo "Actual: ${actual_fib[@]}"
