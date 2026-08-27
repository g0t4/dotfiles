import asyncio
import sys
from pathlib import Path


XONSH_LIB = Path(__file__).parents[2] / ".config" / "xonsh" / "lib"
sys.path.insert(0, str(XONSH_LIB))

from wes_fish_z import FishZEntry  # noqa: E402
from wes_semantic_z import SemanticZ, describe_path  # noqa: E402


class FakeClient:
    async def embed(self, texts):
        vectors = []
        for text in texts:
            vectors.append(
                [
                    float("whisper" in text or "voice" in text),
                    float("dotfiles" in text),
                ]
            )
        return vectors

    async def rerank(self, request):
        return [1.0 if "auto-edit-suggests" in doc else 0.5 for doc in request.docs]


def test_semantic_retrieval_can_ignore_or_blend_frecency(tmp_path):
    voice = tmp_path / "auto-edit-suggests"
    popular = tmp_path / "dotfiles"
    voice.mkdir()
    popular.mkdir()
    entries = [FishZEntry(voice, 1.0), FishZEntry(popular, 100.0)]
    retriever = SemanticZ(FakeClient())

    semantic_only = asyncio.run(
        retriever.retrieve("whisper transcription", entries, use_frecency=False)
    )
    blended = asyncio.run(
        retriever.retrieve("whisper transcription", entries, use_frecency=True)
    )

    assert semantic_only[0].path == voice
    assert semantic_only[0].semantic_rank == 1
    assert blended[0].path == voice
    assert blended[0].score > blended[1].score


def test_empty_query_or_directory_history_never_calls_backend(tmp_path):
    class BackendMustNotRun:
        async def embed(self, _texts):
            raise AssertionError("backend should not run")

    retriever = SemanticZ(BackendMustNotRun())

    assert asyncio.run(retriever.retrieve("", [FishZEntry(tmp_path, 1.0)])) == []
    assert asyncio.run(retriever.retrieve("voice", [])) == []


def test_path_description_adds_lightweight_project_metadata(tmp_path):
    (tmp_path / "pyproject.toml").write_text(
        '[project]\nname = "voice-tools"\ndescription = "Fix transcription"\n'
        'dependencies = ["pywhispercpp"]\n'
    )
    (tmp_path / "README.md").write_text("# Voice tools\nRepairs video flubs.")

    description = describe_path(tmp_path)

    assert "Project name: voice-tools" in description
    assert "Fix transcription" in description
    assert "pywhispercpp" in description
    assert "Repairs video flubs" in description
