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

def hex_to_ascii(hex_str):
    try:
        hex_clean = hex_str[2:] if hex_str.startswith('0x') else hex_str
        ascii_str = unhexlify(hex_clean).decode('ascii')
        return ascii_str
    except:
        return None

def main():
    if len(sys.argv) < 2:
        print("Usage: maths <expression>")
        sys.exit(1)
    
    expr = ' '.join(sys.argv[1:])
    ascii_output = None

    if expr.startswith('"') and expr.endswith('"'):
        expr = expr[1:-1]
        ascii_output = hex_to_ascii(expr) if expr.startswith('0x') else None
        expr = replace_numbers(expr)
    else:
        ascii_output = hex_to_ascii(expr) if re.fullmatch(r'0x[0-9a-fA-F]+', expr) else None
        expr = replace_numbers(expr)
    
    try:
        result = eval(expr)
    except Exception as e:
        print(f"Error evaluating expression: {e}")
        sys.exit(1)
    
    binary = bin(result)
    hexadecimal = hex(result)
    decimal = result

    if ascii_output:
        print(f"ascii: {ascii_output}")
    print(f"bin: {binary}")
    print(f"hex: {hexadecimal}")
    print(f"dec: {decimal}")

if __name__ == "__main__":
    main()