g0t4: 
implement code for this new shell command/function whatever implementation/language as long as you make sure I can use it in the fish shell.

```shell

$ maths 0xFF
bin: 0b11111111
hex: 0xff
dec: 255

$ maths 0xFF + 0xC
bin: 0b100001011
hex: 0x10b
dec: 267

$ maths 0xFF + 10
bin: 0b100001001
hex: 0x109
dec: 265

$ maths 0b10011100
bin: 0b10011100
hex: 0x9c
dec: 156

$ maths 254
bin: 0b11111110
hex: 0xfe
dec: 254

$ maths 0b1101 + 0xA5C3
bin: 0b1010010111010000
hex: 0xa5d0
dec: 42448



$ maths "0x10 | 0x11"
bin: 0b10001
hex: 0x11
dec: 17

$ maths "0x10 & 0x11"
bin: 0b10000
hex: 0x10
dec: 16

$ maths "0x10 ^ 0x11"
bin: 0b1
hex: 0x1
dec: 1

```

GitHub Copilot: ### Plan

1. Create a Fish shell function named `maths`.
2. Parse the input arguments to handle different number formats (binary, hexadecimal, decimal).
3. Evaluate the expression if it contains operators.
4. Convert the result to binary, hexadecimal, and decimal formats.
5. Print the results.

### Code

```fish
function maths
    set -l input (string join " " $argv)
    set -l result (math -s $input)
    
    if test $status -ne 0
        echo "Error: Invalid input"
        return 1
    end

    set -l dec_result (math $result)
    set -l bin_result (math "obase=2; $dec_result" | bc)
    set -l hex_result (math "obase=16; $dec_result" | bc)

    echo "bin: 0b$bin_result"
    echo "hex: 0x$hex_result"
    echo "dec: $dec_result"
end
```

### Usage

Save the function in your Fish configuration file (e.g., `~/.config/fish/config.fish`) or source it directly in your terminal.

```shell
source path/to/your/maths.fish
```

Now you can use the `maths` command as described in your examples.

g0t4: can you write some tests for my scenarios too

GitHub Copilot: ### Plan

1. Create a Fish script to test the `maths` function.
2. Define test cases with expected outputs.
3. Compare the actual output of the `maths` function with the expected output.
4. Print the test results.

### Code

```fish
function run_test
    set -l input $argv[1]
    set -l expected_bin $argv[2]
    set -l expected_hex $argv[3]
    set -l expected_dec $argv[4]

    set -l output (maths $input)
    set -l actual_bin (echo $output | grep -oP 'bin: \K.*')
    set -l actual_hex (echo $output | grep -oP 'hex: \K.*')
    set -l actual_dec (echo $output | grep -oP 'dec: \K.*')

    if test "$actual_bin" = "$expected_bin" -a "$actual_hex" = "$expected_hex" -a "$actual_dec" = "$expected_dec"
        echo "Test passed for input: $input"
    else
        echo "Test failed for input: $input"
        echo "Expected: bin: $expected_bin, hex: $expected_hex, dec: $expected_dec"
        echo "Got: bin: $actual_bin, hex: $actual_hex, dec: $actual_dec"
    end
end

# Test cases
run_test "0xFF" "0b11111111" "0xff" "255"
run_test "0xFF + 0xC" "0b100001011" "0x10b" "267"
run_test "0xFF + 10" "0b100001001" "0x109" "265"
run_test "0b10011100" "0b10011100" "0x9c" "156"
run_test "254" "0b11111110" "0xfe" "254"
run_test "0b1101 + 0xA5C3" "0b1010010111010000" "0xa5d0" "42448"
run_test "0x10 | 0x11" "0b10001" "0x11" "17"
run_test "0x10 & 0x11" "0b10000" "0x10" "16"
run_test "0x10 ^ 0x11" "0b1" "0x1" "1"
```

### Usage

Save the test script to a file, for example `test_maths.fish`, and run it in your terminal:

```shell
source path/to/your/test_maths.fish
```

This will execute the tests and print the results for each test case.

g0t4: math: 0xFF: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0xFF
Expected: bin: 0b11111111, hex: 0xff, dec: 255
Got: bin: , hex: , dec: 
math: 0xFF + 0xC: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0xFF + 0xC
Expected: bin: 0b100001011, hex: 0x10b, dec: 267
Got: bin: , hex: , dec: 
math: 0xFF + 10: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0xFF + 10
Expected: bin: 0b100001001, hex: 0x109, dec: 265
Got: bin: , hex: , dec: 
math: 0b10011100: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0b10011100
Expected: bin: 0b10011100, hex: 0x9c, dec: 156
Got: bin: , hex: , dec: 
math: 254: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 254
Expected: bin: 0b11111110, hex: 0xfe, dec: 254
Got: bin: , hex: , dec: 
math: 0b1101 + 0xA5C3: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0b1101 + 0xA5C3
Expected: bin: 0b1010010111010000, hex: 0xa5d0, dec: 42448
Got: bin: , hex: , dec: 
math: 0x10 | 0x11: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0x10 | 0x11
Expected: bin: 0b10001, hex: 0x11, dec: 17
Got: bin: , hex: , dec: 
math: 0x10 & 0x11: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0x10 & 0x11
Expected: bin: 0b10000, hex: 0x10, dec: 16
Got: bin: , hex: , dec: 
math: 0x10 ^ 0x11: invalid scale value
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
        [-e pattern] [-f file] [--binary-files=value] [--color=when]
        [--context[=num]] [--directories=action] [--label] [--line-buffered]
        [--null] [pattern] [file ...]
Test failed for input: 0x10 ^ 0x11
Expected: bin: 0b1, hex: 0x1, dec: 1
Got: bin: , hex: , dec: 

GitHub Copilot: ### Plan

1. Fix the `maths` function to handle different number formats correctly.
2. Use `bc` for arithmetic operations and conversions.
3. Update the test script to avoid using `grep -P` and handle output parsing correctly.

### Updated `maths` Function

```fish
function maths
    set -l input (string join " " $argv)
    set -l result (echo "$input" | bc)

    if test $status -ne 0
        echo "Error: Invalid input"
        return 1
    end

    set -l dec_result $result
    set -l bin_result (echo "obase=2; $dec_result" | bc)
    set -l hex_result (echo "obase=16; $dec_result" | bc | tr '[:upper:]' '[:lower:]')

    echo "bin: 0b$bin_result"
    echo "hex: 0x$hex_result"
    echo "dec: $dec_result"
end
```

### Updated Test Script

```fish
function run_test
    set -l input $argv[1]
    set -l expected_bin $argv[2]
    set -l expected_hex $argv[3]
    set -l expected_dec $argv[4]

    set -l output (maths $input)
    set -l actual_bin (echo $output | string match -r 'bin: (0b.*)' | string replace 'bin: ' '')
    set -l actual_hex (echo $output | string match -r 'hex: (0x.*)' | string replace 'hex: ' '')
    set -l actual_dec (echo $output | string match -r 'dec: (.*)' | string replace 'dec: ' '')

    if test "$actual_bin" = "$expected_bin" -a "$actual_hex" = "$expected_hex" -a "$actual_dec" = "$expected_dec"
        echo "Test passed for input: $input"
    else
        echo "Test failed for input: $input"
        echo "Expected: bin: $expected_bin, hex: $expected_hex, dec: $expected_dec"
        echo "Got: bin: $actual_bin, hex: $actual_hex, dec: $actual_dec"
    end
end

# Test cases
run_test "0xFF" "0b11111111" "0xff" "255"
run_test "0xFF + 0xC" "0b100001011" "0x10b" "267"
run_test "0xFF + 10" "0b100001001" "0x109" "265"
run_test "0b10011100" "0b10011100" "0x9c" "156"
run_test "254" "0b11111110" "0xfe" "254"
run_test "0b1101 + 0xA5C3" "0b1010010111010000" "0xa5d0" "42448"
run_test "0x10 | 0x11" "0b10001" "0x11" "17"
run_test "0x10 & 0x11" "0b10000" "0x10" "16"
run_test "0x10 ^ 0x11" "0b1" "0x1" "1"
```

### Usage

Save the updated function and test script to their respective files, source them, and run the tests:

```shell
source path/to/your/maths.fish
source path/to/your/test_maths.fish
```

This will execute the tests and print the results for each test case.

g0t4: Parse error: bad expression
    <stdin>:1

Test failed for input: 0xFF
Expected: bin: 0b11111111, hex: 0xff, dec: 255
Got: bin: , hex: , dec: 

Parse error: bad expression
    <stdin>:1

Test failed for input: 0xFF + 0xC
Expected: bin: 0b100001011, hex: 0x10b, dec: 267
Got: bin: , hex: , dec: 

Parse error: bad expression
    <stdin>:1

Test failed for input: 0xFF + 10
Expected: bin: 0b100001001, hex: 0x109, dec: 265
Got: bin: , hex: , dec: 

Parse error: bad expression
    <stdin>:1

Test failed for input: 0b10011100
Expected: bin: 0b10011100, hex: 0x9c, dec: 156
Got: bin: , hex: , dec: 
Test failed for input: 254
Expected: bin: 0b11111110, hex: 0xfe, dec: 254
Got: bin: 0b11111110 hex: 0xfe dec: 254 0b11111110 hex: 0xfe dec: 254, hex: 0xfe dec: 254 0xfe dec: 254, dec: 254 254

Parse error: bad expression
    <stdin>:1

Test failed for input: 0b1101 + 0xA5C3
Expected: bin: 0b1010010111010000, hex: 0xa5d0, dec: 42448
Got: bin: , hex: , dec: 

Parse error: bad expression
    <stdin>:1

Test failed for input: 0x10 | 0x11
Expected: bin: 0b10001, hex: 0x11, dec: 17
Got: bin: , hex: , dec: 

Parse error: bad expression
    <stdin>:1

Test failed for input: 0x10 & 0x11
Expected: bin: 0b10000, hex: 0x10, dec: 16
Got: bin: , hex: , dec: 

Parse error: bad expression
    <stdin>:1

Test failed for input: 0x10 ^ 0x11
Expected: bin: 0b1, hex: 0x1, dec: 1
Got: bin: , hex: , dec: 

GitHub Copilot: ### Plan

1. Fix the `maths` function to handle different number formats correctly.
2. Use `bc` for arithmetic operations and conversions.
3. Update the test script to avoid using `grep -P` and handle output parsing correctly.

### Updated `maths` Function

```fish
function maths
    set -l input (string join " " $argv)
    set -l result (echo "ibase=16; $input" | bc 2>/dev/null)

    if test $status -ne 0
        echo "Error: Invalid input"
        return 1
    end

    set -l dec_result $result
    set -l bin_result (echo "obase=2; $dec_result" | bc)
    set -l hex_result (echo "obase=16; $dec_result" | bc | tr '[:upper:]' '[:lower:]')

    echo "bin: 0b$bin_result"
    echo "hex: 0x$hex_result"
    echo "dec: $dec_result"
end
```

### Updated Test Script

```fish
function run_test
    set -l input $argv[1]
    set -l expected_bin $argv[2]
    set -l expected_hex $argv[3]
    set -l expected_dec $argv[4]

    set -l output (maths $input)
    set -l actual_bin (echo $output | string match -r 'bin: (0b.*)' | string replace 'bin: ' '')
    set -l actual_hex (echo $output | string match -r 'hex: (0x.*)' | string replace 'hex: ' '')
    set -l actual_dec (echo $output | string match -r 'dec: (.*)' | string replace 'dec: ' '')

    if test "$actual_bin" = "$expected_bin" -a "$actual_hex" = "$expected_hex" -a "$actual_dec" = "$expected_dec"
        echo "Test passed for input: $input"
    else
        echo "Test failed for input: $input"
        echo "Expected: bin: $expected_bin, hex: $expected_hex, dec: $expected_dec"
        echo "Got: bin: $actual_bin, hex: $actual_hex, dec: $actual_dec"
    end
end

# Test cases
run_test "0xFF" "0b11111111" "0xff" "255"
run_test "0xFF + 0xC" "0b100001011" "0x10b" "267"
run_test "0xFF + 10" "0b100001001" "0x109" "265"
run_test "0b10011100" "0b10011100" "0x9c" "156"
run_test "254" "0b11111110" "0xfe" "254"
run_test "0b1101 + 0xA5C3" "0b1010010111010000" "0xa5d0" "42448"
run_test "0x10 | 0x11" "0b10001" "0x11" "17"
run_test "0x10 & 0x11" "0b10000" "0x10" "16"
run_test "0x10 ^ 0x11" "0b1" "0x1" "1"
```

### Usage

Save the updated function and test script to their respective files, source them, and run the tests:

```shell
source path/to/your/maths.fish
source path/to/your/test_maths.fish
```

This will execute the tests and print the results for each test case.

g0t4: Test failed for input: 0xFF
Expected: bin: 0b11111111, hex: 0xff, dec: 255
Got: bin: , hex: , dec: 
Test failed for input: 0xFF + 0xC
Expected: bin: 0b100001011, hex: 0x10b, dec: 267
Got: bin: , hex: , dec: 
Test failed for input: 0xFF + 10
Expected: bin: 0b100001001, hex: 0x109, dec: 265
Got: bin: , hex: , dec: 
Test failed for input: 0b10011100
Expected: bin: 0b10011100, hex: 0x9c, dec: 156
Got: bin: , hex: , dec: 
Test failed for input: 254
Expected: bin: 0b11111110, hex: 0xfe, dec: 254
Got: bin: 0b1001010100 hex: 0x254 dec: 596 0b1001010100 hex: 0x254 dec: 596, hex: 0x254 dec: 596 0x254 dec: 596, dec: 596 596
Test failed for input: 0b1101 + 0xA5C3
Expected: bin: 0b1010010111010000, hex: 0xa5d0, dec: 42448
Got: bin: , hex: , dec: 
Test failed for input: 0x10 | 0x11
Expected: bin: 0b10001, hex: 0x11, dec: 17
Got: bin: , hex: , dec: 
Test failed for input: 0x10 & 0x11
Expected: bin: 0b10000, hex: 0x10, dec: 16
Got: bin: , hex: , dec: 
Test failed for input: 0x10 ^ 0x11
Expected: bin: 0b1, hex: 0x1, dec: 1
Got: bin: , hex: , dec: 

GitHub Copilot: ### Plan

1. Fix the `maths` function to handle different number formats correctly.
2. Use `bc` for arithmetic operations and conversions.
3. Update the test script to avoid using `grep -P` and handle output parsing correctly.

### Updated `maths` Function

```fish
function maths
    set -l input (string join " " $argv)
    set -l result (echo "$input" | bc 2>/dev/null)

    if test $status -ne 0
        echo "Error: Invalid input"
        return 1
    end

    set -l dec_result $result
    set -l bin_result (echo "obase=2; $dec_result" | bc)
    set -l hex_result (echo "obase=16; $dec_result" | bc | tr '[:upper:]' '[:lower:]')

    echo "bin: 0b$bin_result"
    echo "hex: 0x$hex_result"
    echo "dec: $dec_result"
end
```

### Updated Test Script

```fish
function run_test
    set -l input $argv[1]
    set -l expected_bin $argv[2]
    set -l expected_hex $argv[3]
    set -l expected_dec $argv[4]

    set -l output (maths $input)
    set -l actual_bin (echo $output | string match -r 'bin: 0b[01]+' | string replace 'bin: ' '')
    set -l actual_hex (echo $output | string match -r 'hex: 0x[0-9a-f]+' | string replace 'hex: ' '')
    set -l actual_dec (echo $output | string match -r 'dec: [0-9]+' | string replace 'dec: ' '')

    if test "$actual_bin" = "$expected_bin" -a "$actual_hex" = "$expected_hex" -a "$actual_dec" = "$expected_dec"
        echo "Test passed for input: $input"
    else
        echo "Test failed for input: $input"
        echo "Expected: bin: $expected_bin, hex: $expected_hex, dec: $expected_dec"
        echo "Got: bin: $actual_bin, hex: $actual_hex, dec: $actual_dec"
    end
end

# Test cases
run_test "0xFF" "0b11111111" "0xff" "255"
run_test "0xFF + 0xC" "0b100001011" "0x10b" "267"
run_test "0xFF + 10" "0b100001001" "0x109" "265"
run_test "0b10011100" "0b10011100" "0x9c" "156"
run_test "254" "0b11111110" "0xfe" "254"
run_test "0b1101 + 0xA5C3" "0b1010010111010000" "0xa5d0" "42448"
run_test "0x10 | 0x11" "0b10001" "0x11" "17"
run_test "0x10 & 0x11" "0b10000" "0x10" "16"
run_test "0x10 ^ 0x11" "0b1" "0x1" "1"
```

### Usage

Save the updated function and test script to their respective files, source them, and run the tests:

```shell
source path/to/your/maths.fish
source path/to/your/test_maths.fish
```

This will execute the tests and print the results for each test case.