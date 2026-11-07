"""Disposable event storage and replaceable derived indexes. No migrations."""
from contextlib import closing
import json
from pathlib import Path
import sqlite3
import uuid

VERSION = 1


class Store:
    def __init__(self, path):
        self.path = Path(path).expanduser().absolute()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with closing(self.connect()) as db, db:
            version = db.execute('PRAGMA user_version').fetchone()[0]
            if version not in (0, VERSION):
                raise RuntimeError('Incompatible command usage store; run command-usage reset')
            db.execute('CREATE TABLE IF NOT EXISTS events (id TEXT PRIMARY KEY, payload TEXT NOT NULL)')
            db.execute('CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT)')
            db.execute('INSERT OR IGNORE INTO metadata VALUES (?, ?)', ('dataset', str(uuid.uuid4())))
            self.dataset = db.execute("SELECT value FROM metadata WHERE key = 'dataset'").fetchone()[0]
            db.execute('CREATE TABLE IF NOT EXISTS resources (event_id TEXT, path TEXT, payload TEXT NOT NULL)')
            db.execute(f'PRAGMA user_version={VERSION}')

    def connect(self):
        return sqlite3.connect(self.path, timeout=2)

    def append(self, event):
        with closing(self.connect()) as db, db:
            db.execute('INSERT INTO events VALUES (?, ?)', (event['id'], json.dumps(event)))

    def events(self):
        with closing(self.connect()) as db:
            return [json.loads(row[0]) for row in db.execute('SELECT payload FROM events ORDER BY rowid')]

    def rebuild(self):
        from .analysis import analyze
        resources = analyze(self.events())['resources']
        with closing(self.connect()) as db, db:
            db.execute('DELETE FROM resources')
            db.executemany('INSERT INTO resources VALUES (?, ?, ?)',
                           [(r['event_id'], r['path'], json.dumps(r)) for r in resources])
        return resources

    def reset(self):
        with closing(self.connect()) as db, db:
            db.execute('DELETE FROM resources')
            db.execute('DELETE FROM events')
