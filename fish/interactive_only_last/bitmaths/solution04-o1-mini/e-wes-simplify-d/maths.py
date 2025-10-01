#!/usr/bin/env python3
import sys
import re
from binascii import unhexlify

def hex_to_ascii(hex_str):
    try:
        hex_clean = hex_str[2:] if hex_str.startswith('0x') else hex_str
        if len(hex_clean) % 2 != 0:
            hex_clean = '0' + hex_clean
        ascii_str = unhexlify(hex_clean).decode('ascii')
        return ascii_str
    except:
        return None

def main():
    if len(sys.argv) < 2:
        print("Usage: maths <expression>")
        sys.exit(1)
    
    expr = ' '.join(sys.argv[1:])
    
    try:
        result = eval(expr)
    except Exception as e:
        print(f"Error evaluating expression: {e}")
        sys.exit(1)
    
    binary = bin(result)
    hexadecimal = hex(result)
    decimal = result
    
    # Convert the result's hex to ASCII
    ascii_output = hex_to_ascii(hexadecimal)
    
    if ascii_output:
        print(f"ascii: {ascii_output}")
    print(f"bin: {binary}")
    print(f"hex: {hexadecimal}")
    print(f"dec: {decimal}")

if __name__ == "__main__":
    main()