"""Xonsh execution evidence; Python audit events are attempts, never syscall tracing."""
import atexit
import os
from pathlib import Path
import queue
import socket
import sys
import threading
import time
import uuid

from .store import Store

_active = None
_audit_installed = False


def _audit(name, args):
    recorder = _active
    if recorder is not None:
        recorder.audit(name, args)


class Recorder:
    def __init__(self, path, *, session=None, origin='cli', correlation=None, python_io=True):
        self.store = Store(path)
        self.session = session or str(uuid.uuid4())
        self.origin, self.correlation = origin, correlation
        self.host, self.pid = socket.gethostname(), os.getpid()
        self.sequence = 0
        self.operation = None
        self.specs = {}
        self.local = threading.local()
        self.python_io = python_io
        self.queue = queue.Queue()
        self.errors = []
        self.handlers = []
        self.closed = False
        self.worker = threading.Thread(target=self._write, daemon=True)
        self.worker.start()

    def _write(self):
        while True:
            event = self.queue.get()
            try:
                if event is None:
                    return
                self.store.append(event)
            except Exception as error:
                if not self.errors:
                    self.errors.append(str(error))
                    print(f'command usage capture: {error}', file=sys.stderr)
            finally:
                self.queue.task_done()

    def emit(self, kind, **data):
        if self.closed:
            return
        self.sequence += 1
        event = dict(id=str(uuid.uuid4()), kind=kind, origin=self.origin, producer='xonsh', dataset=self.store.dataset, ppid=os.getppid(),
                     acquisition='live', session=self.session, operation=self.operation,
                     sequence=self.sequence, timestamp=time.time(), host=self.host, pid=self.pid,
                     cwd=os.getcwd(), correlation=self.correlation, **data)
        self.queue.put(event)
        return event['id']

    def begin(self, cmd, **_):
        self.operation = str(uuid.uuid4())
        self.local.owner = threading.get_ident()
        self.emit('operation_start', source=cmd)

    def finish(self, rtn=None, **_):
        if self.operation is None:
            return
        self.emit('operation_finish', returncode=rtn)
        self.operation = None

    def pre_spec(self, spec, **_):
        if self.operation is None:
            return
        previous = getattr(self.local, 'busy', False)
        self.local.busy = True
        try:
            def stream(value):
                name = getattr(value, 'name', None)
                return {'path': name if isinstance(name, str) else None, 'mode': getattr(value, 'mode', None)}
            argv = [str(a) for a in spec.cmd]
            observed = {}
            for arg in argv[1:]:
                try:
                    observed[arg] = {'exists': Path(arg).exists(), 'directory': Path(arg).is_dir()}
                except (OSError, ValueError):
                    pass
            invocation = self.emit('invocation', argv=argv,
                original_args=[str(a) for a in spec.args], alias=getattr(spec, 'alias_name', None),
                executable=getattr(spec, 'binary_loc', None), background=spec.background,
                pipeline_index=spec.pipeline_index, observed_arguments=observed,
                streams={key: stream(getattr(spec, key)) for key in ('stdin', 'stdout', 'stderr')})
            self.specs[id(spec)] = invocation
        finally:
            self.local.busy = previous

    def post_spec(self, spec, proc=None, **_):
        invocation = self.specs.pop(id(spec), None)
        if invocation:
            self.emit('invocation_started', invocation=invocation, child_pid=getattr(proc, 'pid', None))

    def audit(self, name, args):
        if (not self.python_io or self.operation is None or getattr(self.local, 'busy', False)
                or threading.get_ident() != getattr(self.local, 'owner', None)):
            return
        fields = {'open': (0,), 'os.remove': (0,), 'os.rename': (0, 1), 'os.mkdir': (0,),
                  'os.rmdir': (0,), 'os.listdir': (0,), 'os.scandir': (0,), 'os.chdir': (0,)}
        if name not in fields:
            return
        self.local.busy = True
        try:
            paths = [os.fsdecode(args[i]) for i in fields[name] if i < len(args) and isinstance(args[i], (str, bytes))]
            dirfds = args[2:] if name == 'os.rename' else args[1:] if name in ('os.remove', 'os.rmdir') else args[2:] if name == 'os.mkdir' else ()
            relative_base_known = not any(isinstance(fd, int) and fd >= 0 for fd in dirfds)
            self.emit('python_io_attempt', action=name, paths=paths, relative_base_known=relative_base_known,
                      details=[v if isinstance(v, (str, int, float, bool, type(None))) else type(v).__name__ for v in args])
        except Exception:
            pass  # Diagnostics must never change the operation being observed.
        finally:
            self.local.busy = False

    def install(self):
        global _active, _audit_installed
        from xonsh.events import events
        if _active is not None and _active is not self:
            _active.close()
        _active = self
        if not _audit_installed:
            sys.addaudithook(_audit)
            _audit_installed = True
        for name, callback in [('on_precommand', self.begin), ('on_postcommand', self.finish),
                               ('on_pre_spec_run', self.pre_spec), ('on_post_spec_run', self.post_spec)]:
            event = getattr(events, name)
            def handler(_callback=callback, **kwargs):
                try:
                    return _callback(**kwargs)
                except Exception as error:
                    if not self.errors:
                        self.errors.append(str(error))
                        print(f'command usage capture: {error}', file=sys.stderr)
            event(handler)
            self.handlers.append((event, handler))
        atexit.register(self.close)
        return self

    def execute(self, source):
        """Noninteractive embedding boundary; never used to replay captured source."""
        from xonsh.built_ins import XSH
        self.begin(source)
        result = None
        try:
            XSH.execer.exec(source, glbs=XSH.ctx, locs=XSH.ctx)
        except BaseException as error:
            result = getattr(error, 'returncode', 1)
            raise
        finally:
            self.finish(rtn=result)
            self.flush()

    def flush(self):
        self.queue.join()

    def close(self):
        global _active
        if self.closed:
            return
        if _active is self:
            _active = None
        for event, callback in self.handlers:
            event.discard(callback)
        self.handlers.clear()
        self.closed = True
        self.queue.put(None)
        self.worker.join(timeout=5)
