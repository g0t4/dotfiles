"""Own media subprocesses so closing a window stops its background work."""

import subprocess
from threading import Lock


class Commands:
    def __init__(self):
        self.lock = Lock()
        self.processes = set()
        self.stopped = False

    def spawn(self, command, **kwargs):
        with self.lock:
            if self.stopped:
                raise RuntimeError("Media work cancelled")
            process = subprocess.Popen(command, **kwargs)
            self.processes.add(process)
            return process

    def release(self, process):
        with self.lock:
            self.processes.discard(process)

    def output(self, command, timeout=120):
        process = self.spawn(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            output, error = process.communicate(timeout=timeout)
            if process.returncode:
                raise RuntimeError(
                    error.decode(errors="replace").strip() or "Media command cancelled"
                )
            return output
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            self.release(process)

    def stop(self):
        with self.lock:
            self.stopped = True
            processes = list(self.processes)
        for process in processes:
            try:
                process.kill()
            except ProcessLookupError:
                pass
