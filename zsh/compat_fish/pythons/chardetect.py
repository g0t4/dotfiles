import chardet
import sys
from rich import print

files = sys.argv[1:]
# print(f'{files=}')

for file in files:
    with open(file, "rb") as f:
        raw_data = f.read()
        result = chardet.detect(raw_data)
        print(file)
        print(f"  {result}")
