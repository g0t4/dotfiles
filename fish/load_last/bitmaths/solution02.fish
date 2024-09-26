function maths
    set -l expression (string join " " $argv)
    set -l result (math "obase=10; ibase=16; $expression" | bc)
    set -l bin_result (math "obase=2; $result" | bc)
    set -l hex_result (math "obase=16; $result" | bc)
    echo "bin: 0b$bin_result"
    echo "hex: 0x$hex_result"
    echo "dec: $result"
end