function maths
    python3 - <<EOF
import sys
import re

def parse_number(s):
    if s.startswith('0b'):
        return int(s, 2)
    elif s.startswith('0x'):
        return int(s, 16)
    else:
        return int(s)

def replace_numbers(expr):
    return re.sub(r'0b[01]+|0x[0-9a-fA-F]+|\d+', lambda x: str(parse_number(x.group())), expr)

def main():
    if len(sys.argv) < 2:
        print("Usage: maths <expression>")
        sys.exit(1)
    
    expr = ' '.join(sys.argv[1:])
    
    if expr.startswith('"') and expr.endswith('"'):
        expr = expr[1:-1]
        expr = replace_numbers(expr)
    else:
        expr = replace_numbers(expr)
    
    try:
        result = eval(expr)
    except Exception as e:
        print(f"Error evaluating expression: {e}")
        sys.exit(1)
    
    binary = bin(result)
    hexadecimal = hex(result)
    decimal = result
    
    print(f"bin: {binary}")
    print(f"hex: {hexadecimal}")
    print(f"dec: {decimal}")

if __name__ == "__main__":
    main()
EOF
end