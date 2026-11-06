"""Read-only launcher history diagnostics, including paths hidden from normal search."""
import math
import os
from pathlib import Path
import stat
import time

from wes_file_history import FileHistory, match_score
from wes_fish_z import FishZ


def filesystem(path):
    result = {}
    try:
        link = os.lstat(path)
        if stat.S_ISLNK(link.st_mode):
            result['symlink_target'] = os.readlink(path)
        metadata = os.stat(path)
    except FileNotFoundError:
        return {**result, 'status': 'missing', 'reason': 'Not found (possibly moved, deleted, or on an unavailable volume)'}
    except OSError as error:
        return {**result, 'status': 'unavailable', 'reason': str(error)}
    kind = 'directory' if stat.S_ISDIR(metadata.st_mode) else 'file' if stat.S_ISREG(metadata.st_mode) else 'other'
    return {**result, 'status': 'exists', 'kind': kind, 'size': metadata.st_size,
            'permissions': stat.filemode(metadata.st_mode), 'uid': metadata.st_uid, 'gid': metadata.st_gid,
            'modified': metadata.st_mtime, 'accessed': metadata.st_atime,
            'metadata_changed': metadata.st_ctime, 'created': getattr(metadata, 'st_birthtime', None)}


def z_frecency(rank, stamp, now):
    age = now - stamp
    return rank * (4 if age < 3600 else 2 if age < 86400 else .5 if age < 604800 else .25)


def diagnose(query, history=None, z=None, limit=30):
    history, z = history or FileHistory(), z or FishZ()
    now = time.time()
    records, warnings = {}, []
    try:
        sources = history.sources()
        for path, count, stamp in history.entries():
            provenance = list(sources.get(path, []))
            unknown = count - sum(item['opens'] for item in provenance)
            if unknown:
                provenance.append({'source': 'before source tracking', 'opens': unknown})
            records.setdefault(path, {'path': path, 'sources': []})['sources'].append({
                'source': 'File-open history', 'database': str(history.database), 'opens': count,
                'last_open': stamp, 'recorded_by': provenance,
                'reason': 'A default-app file open was accepted; browsing and previews do not count.',
                'usage_score': math.log1p(count) / (1 + max(0, now - stamp) / 86400),
            })
    except Exception as error:
        warnings.append(f'File history: {error}')
    try:
        database, entries = z.diagnostic_snapshot()
        for entry in entries:
            path = entry['path']
            records.setdefault(path, {'path': path, 'sources': []})['sources'].append({
                'source': 'z directory history', 'database': database, 'rank': entry['rank'],
                'last_visit': entry['last_visit'], 'usage_score': z_frecency(entry['rank'], entry['last_visit'], now),
                'reason': 'Recorded by shared z directory tracking (shell cd or Pip Rot navigation). z does not identify which one.',
            })
    except Exception as error:
        warnings.append(f'z history: {error}')
    # An explicit path can be inspected even if it has never been tracked.
    if query.startswith(('/', '~')):
        path = os.path.abspath(Path(query).expanduser())
        records.setdefault(path, {'path': path, 'sources': []})
        candidates = [(0, records[path])]
    else:
        candidates = [(score, entry) for path, entry in records.items()
                      if (score := match_score(path, query)) is not None]
    candidates.sort(key=lambda item: (item[0], max((source.get('last_open', source.get('last_visit', 0)) for source in item[1]['sources']), default=0), item[1]['path']), reverse=True)
    results = []
    for score, entry in candidates[:limit]:
        entry['filesystem'] = filesystem(entry['path'])
        entry['match_score'] = score
        entry['inspected_at'] = time.time()
        entry['normal_search'] = ('Not tracked' if not entry['sources'] else
                                  'Hidden: ' + entry['filesystem']['status'] if entry['filesystem']['status'] != 'exists' else
                                  'Eligible; query matching and the 30-result limit still apply')
        if (entry['filesystem'].get('kind') != 'directory' and entry['sources']
                and all(source['source'] == 'z directory history' for source in entry['sources'])
                and entry['filesystem']['status'] == 'exists'):
            entry['normal_search'] = 'Hidden: z history entry is no longer a directory'
        results.append(entry)
    return {'entries': results, 'warnings': warnings, 'matches': len(candidates),
            'note': 'Diagnostics include missing paths. Ranking: filename/path match first, then usage; empty search uses recency. File and z usage scores use different scales. stat access time is not tracked usage.'}
