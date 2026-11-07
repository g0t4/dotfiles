import argparse
import json
import sys

from . import Store, default_path, explain_source


def main(argv=None):
    parser = argparse.ArgumentParser(description='Disposable command usage diagnostics; never replays captured commands')
    parser.add_argument('--database', default=str(default_path()))
    parser.add_argument('action', choices=['events', 'explain', 'rebuild', 'reset'])
    parser.add_argument('source', nargs='?')
    args = parser.parse_args(argv)
    if args.action == 'reset':
        # Works even when the old schema cannot be opened. Stop recorders first.
        from pathlib import Path
        path = Path(args.database).expanduser().absolute()
        for suffix in ('', '-wal', '-shm', '-journal'):
            Path(str(path)+suffix).unlink(missing_ok=True)
        print('Command usage reset')
        return 0
    if args.action == 'explain':
        print(json.dumps(explain_source(args.source or sys.stdin.read()), indent=2))
        return 0
    store = Store(args.database)
    print(json.dumps(store.events() if args.action == 'events' else store.rebuild(), indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
