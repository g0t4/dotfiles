#!/bin/bash

function fibonacci {
    if [ $1 -eq 0 ]; then
        echo 0
    elif [ $1 -eq 1 ]; then
        echo 1
    else
        fib_result_1=$(fibonacci $(($1-1)))
        fib_result_2=$(fibonacci $(($1-2)))
        echo $(($fib_result_1 + $fib_result_2))
    fi
}

echo "Fibonacci for n=2: Expected value: 1; Actual value: $(fibonacci 2)"
echo "Fibonacci for n=3: Expected value: 2; Actual value: $(fibonacci 3)"
echo "Fibonacci for n=4: Expected value: 3; Actual value: $(fibonacci 4)"
echo "Fibonacci for n=5: Expected value: 5; Actual value: $(fibonacci 5)"
echo "Fibonacci for n=6: Expected value: 8; Actual value: $(fibonacci 6)"

function fibonacci_test {
    for n in 2 3 4 5 6; do
        actual_value=$(fibonacci $n)
        if [ $n -eq 2 ]; then
            expected_value=1
        elif [ $n -eq 3 ]; then
            expected_value=2
        elif [ $n -eq 4 ]; then
            expected_value=3
        elif [ $n -eq 5 ]; then
            expected_value=5
        else
            expected_value=8
        fi
        echo "Fibonacci for n=$n: Expected value: $expected_value; Actual value: $actual_value"
    done
}

echo "Testing Fibonacci function..."
fibonacci_test
