import time


class Timer:

    def __init__(self, description: str, group: bool = False, nested: bool = False):
        self.description = description
        self.nested = nested
        self.group = group
        self.children = []
        self.elapsed_us = 0.0
        self.duration = ""

    def __enter__(self):
        self.start_ns = time.time_ns()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.end_ns = time.time_ns()
        elapsed_ns = self.end_ns - self.start_ns
        elapsed_us = elapsed_ns / 1000
        if elapsed_us < 1000:
            duration = f'{elapsed_us=}'
        else:
            elapsed_ms = elapsed_us / 1000
            duration = f'{elapsed_ms=}'
        self.elapsed_us = elapsed_us
        self.duration = duration
        if not self.nested:
            print(f"{duration} {self.description}")
            for c in self.children:
                # PRN multiple nesting levels
                print(f"    {c.duration} {c.description}")

    def group(self, description: str):
        return Timer(description, group=True)

    def nest(self, description: str):
        child = Timer(description, nested=True)
        self.children.append(child)
        return child

    def elapsed_us(self):
        if self.end_ns is None:
            return (time.time_ns() - self.start_ns) / 1000
        return (self.end_ns - self.start_ns) / 1000


# EXAMPLE USE:
# with Timer("foo'ing"):
#     # Code block whose execution time you want to measure
#     for i in range(1000000):
#         pass
