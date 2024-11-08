#!/bin/bash
fib() {
    if [ $1 -le 1 ]; then
        echo $1
    else
        local result_fib_2=$(fib $(($1-1)))
        local result_fib_1=$(fib $(($1-2)))
        echo $((result_fib_1 + result_fib_2))
    fi
}
echo "fib 1 | expected: 1 | actual: $(fib 1)"
echo "fib 2 | expected: 1 | actual: $(fib 2)"
echo "fib 3 | expected: 2 | actual: $(fib 3)"
echo "fib 4 | expected: 3 | actual: $(fib 4)"
echo "fib 5 | expected: 5 | actual: $(fib 5)"
