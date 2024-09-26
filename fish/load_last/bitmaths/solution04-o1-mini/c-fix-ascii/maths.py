#!/usr/bin/env python3
import sys
import re
from binascii import unhexlify

def parse_number(s):
    if s.startswith('0b'):
        return int(s, 2)
    elif s.startswith('0x'):
        return int(s, 16)
    else:
        return int(s)

def replace_numbers(expr):
    return re.sub(r'0b[01]+|0x[0-9a-fA-F]+|\d+', lambda x: str(parse_number(x.group())), expr)

def extract_hex_numbers(expr):
    return re.findall(r'0x[0-9a-fA-F]+', expr)

def hex_to_ascii(hex_str):
    try:
        hex_clean = hex_str[2:] if hex_str.startswith('0x') else hex_str
        # Ensure even number of characters for unhexlify
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
    ascii_outputs = []

    if expr.startswith('"') and expr.endswith('"'):
        expr = expr[1:-1]
    
    # Extract hex numbers for ASCII conversion
    hex_numbers = extract_hex_numbers(expr)
    for hex_num in hex_numbers:
        ascii_str = hex_to_ascii(hex_num)
        if ascii_str:
            ascii_outputs.append(ascii_str)
    
    # Replace numbers for evaluation
    expr_evaluated = replace_numbers(expr)
    
    try:
        result = eval(expr_evaluated)
    except Exception as e:
        print(f"Error evaluating expression: {e}")
        sys.exit(1)
    
    binary = bin(result)
    hexadecimal = hex(result)
    decimal = result

    if ascii_outputs:
        print(f"ascii: {' '.join(ascii_outputs)}")
    print(f"bin: {binary}")
    print(f"hex: {hexadecimal}")
    print(f"dec: {decimal}")

if __name__ == "__main__":
    main()