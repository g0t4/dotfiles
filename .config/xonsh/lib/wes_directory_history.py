"""Fish-style bidirectional working-directory history."""

from collections.abc import Callable
from dataclasses import dataclass, field


@dataclass
class DirectoryHistory:
    """Track ordinary directory changes and navigate backward or forward."""

    limit: int = 25
    previous: list[str] = field(default_factory=list)
    following: list[str] = field(default_factory=list)
    _navigating: bool = False

    def record(self, olddir: str, newdir: str) -> None:
        if self._navigating or olddir == newdir:
            return
        self.previous.append(olddir)
        del self.previous[: -self.limit]
        self.following.clear()

    def back(self, current: str, change_directory: Callable[[str], object]) -> bool:
        return self._navigate(current, self.previous, self.following, change_directory)

    def forward(
        self, current: str, change_directory: Callable[[str], object]
    ) -> bool:
        return self._navigate(current, self.following, self.previous, change_directory)

    def _navigate(
        self,
        current: str,
        source: list[str],
        destination: list[str],
        change_directory: Callable[[str], object],
    ) -> bool:
        if not source:
            return False

        target = source.pop()
        destination.append(current)
        self._navigating = True
        try:
            change_directory(target)
        except BaseException:
            destination.pop()
            source.append(target)
            raise
        finally:
            self._navigating = False
        return True
