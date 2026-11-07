"""Pure, deterministic evidence interpretation. No expression evaluation or IO."""
import ast
import os


def absolute(path, cwd):
    # No expandvars/expanduser/globbing: runtime argv is already resolved.
    return os.path.normpath(path if os.path.isabs(path) else os.path.join(cwd, path))


def analyze(events):
    resources, unknown = [], []
    for event in events:
        common = {key: event.get(key) for key in ('session', 'operation', 'origin', 'acquisition', 'timestamp')}
        common['event_id'] = event['id']
        def add(path, role, evidence, command=None):
            if path and '\0' not in path:
                resources.append(dict(common, path=absolute(path, event['cwd']), spelling=path,
                                      role=role, evidence=evidence, command=command))
        if event['kind'] == 'python_io_attempt':
            for index, path in enumerate(event['paths']):
                if not os.path.isabs(path) and not event.get('relative_base_known', True):
                    unknown.append({'event_id': event['id'], 'reason': 'Relative IO path uses an unresolved directory descriptor'})
                    continue
                add(path, event['action'] + (f':{index}' if len(event['paths']) > 1 else ''), 'python-audit-attempt')
        elif event['kind'] == 'invocation':
            argv = event['argv']
            command = event.get('alias') or os.path.basename(argv[0])
            operands = [a for a in argv[1:] if not a.startswith('-')]
            if command == 'jq' and operands:
                operands = operands[1:]  # Simple jq filter; complex options remain heuristic.
            if command in ('grep', 'rg') and operands:
                operands = operands[1:]
            for index, arg in enumerate(operands):
                observation = event.get('observed_arguments', {}).get(arg, {})
                if not (observation.get('exists') or '/' in arg or command in ('touch', 'rm', 'cp', 'mv', 'mkdir', 'rmdir')):
                    continue
                role = {'cat': 'input', 'touch': 'create-or-update', 'rm': 'delete',
                        'mkdir': 'create-directory', 'rmdir': 'delete-directory', 'jq': 'input'}.get(command, 'operand')
                if command in ('cp', 'mv'):
                    role = 'destination' if index == len(operands)-1 else 'source'
                add(arg, role, 'runtime-argument-candidate', command)
            for stream, info in event.get('streams', {}).items():
                if info.get('path'):
                    add(info['path'], 'input' if stream == 'stdin' else 'output', 'runtime-stream', command)
            unknown.append({'event_id': event['id'], 'reason': 'Child/internal IO not observed; argv roles are heuristic'})
    # Stable deduplication: an audit event and a stream event remain distinct evidence.
    unique = {(r['event_id'], r['path'], r['role'], r['evidence']): r for r in resources}
    return {'resources': list(unique.values()), 'unknown': unknown}


def explain_source(source):
    """Parse Xonsh syntax without running it; unresolved values remain unresolved."""
    from xonsh.execer import Execer
    try:
        tree = Execer().parse(source, ctx=set(), mode='exec')
    except Exception as error:
        return {'source': source, 'commands': [], 'unknown': [str(error)]}
    def words(node):
        if isinstance(node, (ast.List, ast.Tuple)):
            return [token for item in node.elts for token in words(item)]
        if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add):
            return words(node.left) + words(node.right)
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            return [node.value]
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                and isinstance(node.func.value, ast.Name) and node.func.value.id == '__xonsh__'
                and node.func.attr == 'expand_path' and node.args):
            return words(node.args[0])
        return [{'unresolved': ast.unparse(node)}]

    commands = []
    for node in ast.walk(tree):
        if (not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute)
                or not isinstance(node.func.value, ast.Name) or node.func.value.id != '__xonsh__'
                or not node.func.attr.startswith('subproc_') or node.func.attr == 'subproc_check_boolop'):
            continue
        commands.extend(words(arg) for arg in node.args if not isinstance(arg, ast.Constant))
    return {'source': source, 'commands': commands,
            'unknown': ['Static parse only: no runtime variables, aliases, glob expansion, or Python IO inferred']}
