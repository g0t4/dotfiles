"""Shared history of deliberate file opens; no crawling or content indexing."""
from __future__ import annotations

from contextlib import closing, contextmanager
import argparse
import json
import math
import os
from pathlib import Path
import sqlite3
import sys
import time


class FileHistory:
    def __init__(self, database=None):
        state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')))
        self.database = (Path(database) if database else state / 'file-history/history.sqlite3').expanduser().absolute()

    @contextmanager
    def connect(self):
        self.database.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.database, timeout=2)
        try:
            with connection:
                connection.execute('CREATE TABLE IF NOT EXISTS files (path TEXT PRIMARY KEY, opens INTEGER NOT NULL, last_open REAL NOT NULL)')
                connection.execute('CREATE TABLE IF NOT EXISTS file_sources (path TEXT NOT NULL, source TEXT NOT NULL, opens INTEGER NOT NULL, last_open REAL NOT NULL, PRIMARY KEY(path, source))')
                yield connection
        finally:
            connection.close()

    def record(self, path, source='unspecified'):
        path = Path(os.path.abspath(Path(path).expanduser()))
        if not path.is_file():
            return False
        stamp = time.time()
        with self.connect() as connection:
            connection.execute('INSERT INTO files VALUES (?, 1, ?) ON CONFLICT(path) DO UPDATE SET opens = opens + 1, last_open = excluded.last_open', (str(path), stamp))
            connection.execute('INSERT INTO file_sources VALUES (?, ?, 1, ?) ON CONFLICT(path, source) DO UPDATE SET opens = opens + 1, last_open = excluded.last_open', (str(path), source, stamp))
        return True

    def entries(self):
        if not self.database.exists():
            return []
        with closing(sqlite3.connect(self.database.as_uri() + '?mode=ro', uri=True)) as connection:
            return list(connection.execute('SELECT path, opens, last_open FROM files'))

    def sources(self):
        if not self.database.exists():
            return {}
        with closing(sqlite3.connect(self.database.as_uri() + '?mode=ro', uri=True)) as connection:
            if not connection.execute("SELECT 1 FROM sqlite_master WHERE name = 'file_sources'").fetchone():
                return {}
            result = {}
            for path, source, count, stamp in connection.execute('SELECT path, source, opens, last_open FROM file_sources'):
                result.setdefault(path, []).append({'source': source, 'opens': count, 'last_open': stamp})
            return result

    def forget(self, path):
        if self.database.exists():
            with self.connect() as connection:
                absolute = os.path.abspath(Path(path).expanduser())
                connection.execute('DELETE FROM files WHERE path = ?', (absolute,))
                connection.execute('DELETE FROM file_sources WHERE path = ?', (absolute,))


def match_score(path, query):
    """All words must match; tight and basename matches beat loose path matches."""
    text, name = str(path).casefold(), Path(path).name.casefold()
    def tightness(text, word):
        if word in text:
            return 10 * len(word) + 20
        position, first = -1, None
        for character in word:
            position = text.find(character, position + 1)
            if position < 0:
                return None
            if first is None:
                first = position
        return 10 * len(word) - (position - first)

    total = 0
    for word in query.casefold().split():
        score = tightness(name, word)
        if score is not None:
            total += score + 50 + (100 if word == name else 0)
        else:
            score = tightness(text, word)
            if score is None:
                return None
            total += score
    return total


def search(query, history=None, directories=(), limit=30):
    now = time.time()
    candidates = [(path, 'file', math.log1p(count) / (1 + max(0, now - stamp) / 86400), stamp)
                  for path, count, stamp in (history or FileHistory()).entries()]
    candidates.extend((str(entry.path), 'directory', entry.frecency, 0) for entry in directories)
    ranked = []
    for path, kind, usage, stamp in candidates:
        score = match_score(path, query)
        if score is None or not Path(path).exists():
            continue
        # Match quality is primary. Existing z scores remain authoritative for directories.
        ranked.append(((score, usage if query.strip() else (stamp or usage), path), {'path': path, 'kind': kind}))
    return [item for _, item in sorted(ranked, reverse=True)[:limit]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['record', 'search', 'forget', 'info'])
    parser.add_argument('value')
    parser.add_argument('--source', default='unspecified', choices=['unspecified', 'pip-rot', 'launcher'])
    args = parser.parse_args()
    history = FileHistory()
    if args.action == 'record':
        history.record(args.value, args.source)
    elif args.action == 'info':
        from wes_history_diagnostics import diagnose
        print(json.dumps(diagnose(args.value, history)))
    elif args.action == 'forget':
        history.forget(args.value)
    else:
        from wes_fish_z import FishZ, FishZError
        try:
            directories = FishZ().entries(recent=not args.value.strip())
        except FishZError as error:
            print(error, file=sys.stderr)
            directories = []
        print(json.dumps(search(args.value, history, directories)))


if __name__ == '__main__':
    main()
