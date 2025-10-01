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