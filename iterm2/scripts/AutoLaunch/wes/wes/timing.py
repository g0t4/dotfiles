import time

class Timer:

    def __init__(self, description: str):
        self.description = description

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
        print(f"{self.description}: {duration}")

# EXAMPLE USE:
# with Timer("foo'ing"):
#     # Code block whose execution time you want to measure
#     for i in range(1000000):
#         pass
