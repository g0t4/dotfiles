import chardet
import sys
from pathlib import Path
from rich import print

files = sys.argv[1:]
# print(f'{files=}')

for file in files:
    file_path = Path(file)
    if file_path.is_dir():
        # this comes up if you do `chardetect *` ...
        # skipping saves you from needing to use `cardetect *.*`
        # ? should I add recursive flag and check these then?
        print(f"Skipping directory: {file}")
        continue

    with open(file, "rb") as f:
        raw_data = f.read()
        result = chardet.detect(raw_data)
        print(file)
        print(f"  {result}")
