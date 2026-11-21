"""Named, restorable snapshots of Clanker's active conversation context."""

from __future__ import annotations

import fcntl
import json
import os
import tempfile
from contextlib import contextmanager
from copy import deepcopy
from pathlib import Path
from uuid import uuid4


def conversation_title(session):
    for record in session.messages:
        if record["message"]["role"] == "user" and not record["metadata"].get(
            "steering"
        ):
            text = " ".join(str(record["message"]["content"]).split())
            return text[:80] or "Untitled conversation"
    return "Untitled conversation"


class SavedConversations:
    def __init__(self, directory):
        self.directory = Path(directory)

    @contextmanager
    def _locked(self):
        # Lock a stable inode: snapshots themselves are replaced atomically.
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (self.directory / ".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            yield

    def list(self):
        if not self.directory.exists():
            return []
        snapshots = []
        for path in self.directory.glob("*.json"):
            try:
                item = json.loads(path.read_text())
                if (
                    isinstance(item, dict)
                    and item.get("version") == 1
                    and item.get("conversation_id") == path.stem
                    and isinstance(item.get("title"), str)
                    and isinstance(item.get("restore_count", 0), int)
                    and isinstance(item.get("updated_at"), str)
                    and isinstance(item.get("last_restored_at") or "", str)
                    and isinstance(item.get("created_at"), str)
                    and isinstance(item.get("messages"), list)
                    and item["messages"]
                    and all(
                        isinstance(record, dict)
                        and isinstance(record.get("metadata"), dict)
                        and isinstance(record.get("message"), dict)
                        and record["message"].get("role")
                        in ("user", "assistant", "tool", "system")
                        and "content" in record["message"]
                        for record in item["messages"]
                    )
                ):
                    snapshots.append(item)
            except (OSError, UnicodeError, json.JSONDecodeError):
                continue
        return sorted(
            snapshots,
            key=lambda item: (
                item.get("restore_count", 0),
                item.get("last_restored_at") or item["updated_at"],
            ),
            reverse=True,
        )

    def save(self, session, title=None):
        if session.active:
            raise RuntimeError("Cannot save a conversation during an active turn")
        if not session.has_conversation():
            raise RuntimeError("No conversation is available to save")
        from clanker_session import timestamp

        with self._locked():
            existing = self._load_id(session.saved_conversation_id)
            conversation_id = session.saved_conversation_id or uuid4().hex
            chosen_title = (
                title or session.saved_conversation_title or conversation_title(session)
            )
            now = timestamp()
            snapshot = {
                "version": 1,
                "conversation_id": conversation_id,
                "title": chosen_title,
                "created_at": existing["created_at"] if existing else now,
                "updated_at": now,
                "restore_count": existing.get("restore_count", 0) if existing else 0,
                "last_restored_at": existing.get("last_restored_at")
                if existing
                else None,
                "messages": deepcopy(session.messages),
            }
            self._write(snapshot)
        session.saved_conversation_id = conversation_id
        session.saved_conversation_title = chosen_title
        return snapshot

    def rename(self, session, title):
        title = title.strip()
        if not title:
            raise RuntimeError("A conversation title is required")
        return self.save(session, title)

    def restore(self, session, query=None):
        if session.active:
            raise RuntimeError("Cannot restore a conversation during an active turn")
        from clanker_session import timestamp

        with self._locked():
            snapshots = self.list()
            if not snapshots:
                raise RuntimeError("No saved Clanker conversations")
            snapshot = self._select(snapshots, query)
            snapshot["restore_count"] = snapshot.get("restore_count", 0) + 1
            snapshot["last_restored_at"] = timestamp()
            self._write(snapshot)
        messages = deepcopy(snapshot["messages"])
        # Older saves made after restore have collapsed turn IDs. Ordinary
        # user messages still identify turn starts; steering belongs to its turn.
        local_turn = session.turn
        for record in messages:
            if record["message"]["role"] == "user" and not record["metadata"].get(
                "steering"
            ):
                local_turn += 1
            record["turn_id"] = local_turn
        session.append(
            "context_restore",
            conversation_id=snapshot["conversation_id"],
            title=snapshot["title"],
            snapshot_version=snapshot["version"],
            after_turn_id=session.turn,
        )
        session.turn = local_turn
        session.messages[:] = messages
        session.saved_conversation_id = snapshot["conversation_id"]
        session.saved_conversation_title = snapshot["title"]
        return snapshot

    def _select(self, snapshots, query):
        if not query:
            return snapshots[0]
        folded = query.casefold().strip()
        identifier = [
            item
            for item in snapshots
            if item["conversation_id"].casefold().startswith(folded)
        ]
        if len(identifier) == 1:
            return identifier[0]
        exact = [item for item in snapshots if item["title"].casefold() == folded]
        if len(exact) == 1:
            return exact[0]
        matches = (
            exact
            or identifier
            or [item for item in snapshots if folded in item["title"].casefold()]
        )
        if len(matches) == 1:
            return matches[0]
        if not matches:
            raise RuntimeError(f"No saved conversation matches: {query}")
        names = ", ".join(
            f"{item['title']} ({item['conversation_id']})" for item in matches
        )
        raise RuntimeError(f"Saved conversation name is ambiguous: {names}")

    def _load_id(self, conversation_id):
        if not conversation_id:
            return None
        path = self.directory / f"{conversation_id}.json"
        try:
            return json.loads(path.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            return None

    def _write(self, snapshot):
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        path = self.directory / f"{snapshot['conversation_id']}.json"
        descriptor, temporary = tempfile.mkstemp(
            prefix=f".{snapshot['conversation_id']}.", dir=self.directory
        )
        try:
            with os.fdopen(descriptor, "w") as stream:
                json.dump(
                    snapshot,
                    stream,
                    ensure_ascii=False,
                    separators=(",", ":"),
                    default=str,
                )
                stream.write("\n")
            os.chmod(temporary, 0o600)
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
