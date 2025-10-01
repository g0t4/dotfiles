#!/usr/bin/env python3
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: maths <expression>")
        return

    expression = sys.argv[1]
    try:
        result = eval(expression)
    except Exception as e:
        print(f"Error evaluating expression: {e}")
        return

    print(f"bin: {bin(result)}")
    print(f"hex: {hex(result)}")
    print(f"dec: {result}")

if __name__ == "__main__":
    main()

# from copilot via gpt-4o in vscode chat
