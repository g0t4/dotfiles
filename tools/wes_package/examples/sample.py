"""Python color specimen: scan structure, then read the details."""

import asyncio
from dataclasses import dataclass
from pathlib import Path

# Comments should be readable without competing with the code.
MAX_RETRIES = 3
SCALE = 1.25
MASK = 0xFF


@dataclass(frozen=True)
class Result:
    path: Path
    content: str | None = None

    def summary(self) -> str:
        """Docstrings share the comment color; strings carry data."""
        size = len(self.content or "")
        return f"{self.path.name}: {size:04d} bytes\n"


async def read_file(path: Path, retries: int = MAX_RETRIES) -> Result:
    for attempt in range(retries):
        try:
            content = await asyncio.to_thread(path.read_text)
            if not content.strip():
                raise ValueError("empty input")
            return Result(path, content)
        except (OSError, ValueError) as error:
            print(f"attempt {attempt + 1}: {error!r}")
            await asyncio.sleep(0.25 * (2 ** attempt))
    return Result(path, None)


def select_names(records: list[dict[str, object]]) -> list[str]:
    pattern = r"\b[a-z_]+\b"
    names = [str(row["name"]) for row in records if row.get("active") is True]
    match names:
        case [first, *rest] if len(rest) > 0:
            print("first:", first, "remaining:", rest, "pattern:", pattern)
        case []:
            print('nothing selected — punctuation should stay quiet')
    return sorted(names, key=lambda name: name.casefold())
