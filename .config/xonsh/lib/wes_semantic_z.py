"""Semantic directory retrieval over the existing Fish-z database."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Sequence
import tomllib

from wes_fish_z import FishZEntry
from wes_semantic_history import InferenceClient, RerankRequest, rank_by_embedding


@dataclass(frozen=True)
class SemanticZMatch:
    path: Path
    semantic_rank: int
    frecency_rank: int
    score: float


def _project_metadata(path: Path) -> list[str]:
    details = []
    pyproject = path / "pyproject.toml"
    if pyproject.is_file():
        try:
            project = tomllib.loads(pyproject.read_text()).get("project", {})
            for key in ("name", "description"):
                if value := project.get(key):
                    details.append(f"Project {key}: {value}")
            dependencies = project.get("dependencies", [])
            if dependencies:
                details.append("Python dependencies: " + ", ".join(dependencies))
        except (OSError, tomllib.TOMLDecodeError):
            pass
    for name in ("README.md", "README", "readme.md"):
        readme = path / name
        if not readme.is_file():
            continue
        try:
            excerpt = " ".join(readme.read_text(errors="replace")[:1200].split())
        except OSError:
            continue
        if excerpt:
            details.append(f"README excerpt: {excerpt}")
        break
    return details


def describe_path(path: Path) -> str:
    words = str(path).replace("-", " ").replace("_", " ").replace(".", " ")
    lines = [f"Directory path: {path}", f"Path words: {words}"]
    lines.extend(_project_metadata(path))
    return "\n".join(lines)


class SemanticZ:
    INSTRUCTION = "Find the local directory that best matches the user's description."

    def __init__(self, client: InferenceClient, *, candidate_limit: int = 24):
        self.client = client
        self.candidate_limit = candidate_limit
        self.vectors: dict[Path, list[float]] = {}

    async def retrieve(
        self,
        query: str,
        entries: Sequence[FishZEntry],
        *,
        limit: int = 8,
        use_frecency: bool = True,
    ) -> list[SemanticZMatch]:
        if not query.strip() or not entries:
            return []

        unique = {entry.path: entry for entry in entries}
        candidates = list(unique.values())
        missing = [entry for entry in candidates if entry.path not in self.vectors]
        if missing:
            vectors = await self.client.embed(
                [describe_path(entry.path) for entry in missing]
            )
            self.vectors.update(
                (entry.path, vector)
                for entry, vector in zip(missing, vectors, strict=True)
            )

        formatted_query = f"Instruct: {self.INSTRUCTION}\nQuery: {query}"
        query_vector = (await self.client.embed([formatted_query]))[0]
        shortlist_paths = rank_by_embedding(
            query_vector,
            ((str(entry.path), self.vectors[entry.path]) for entry in candidates),
            limit=min(self.candidate_limit, len(candidates)),
        )
        shortlist = [unique[Path(path)] for path in shortlist_paths]
        docs = [describe_path(entry.path) for entry in shortlist]
        rerank_scores = await self.client.rerank(
            RerankRequest(self.INSTRUCTION, query, docs)
        )
        semantic = [
            entry
            for _score, entry in sorted(
                zip(rerank_scores, shortlist, strict=True),
                key=lambda pair: pair[0],
                reverse=True,
            )
        ]
        semantic_ranks = {entry.path: rank for rank, entry in enumerate(semantic, 1)}
        by_frecency = sorted(shortlist, key=lambda entry: entry.frecency, reverse=True)
        frecency_ranks = {entry.path: rank for rank, entry in enumerate(by_frecency, 1)}
        count = max(1, len(shortlist) - 1)

        matches = []
        for entry in shortlist:
            semantic_rank = semantic_ranks[entry.path]
            frecency_rank = frecency_ranks[entry.path]
            semantic_score = 1.0 - (semantic_rank - 1) / count
            frecency_score = 1.0 - (frecency_rank - 1) / count
            score = (
                0.8 * semantic_score + 0.2 * frecency_score
                if use_frecency
                else semantic_score
            )
            matches.append(
                SemanticZMatch(entry.path, semantic_rank, frecency_rank, score)
            )
        return sorted(matches, key=lambda match: match.score, reverse=True)[:limit]
