import time


class Timer:

    def __enter__(self):
        self.start_ns = time.time_ns()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.end_ns = time.time_ns()
        elapsed_ns = self.end_ns - self.start_ns
        elapsed_us = elapsed_ns / 1000
        print(f"Time consumed: {elapsed_us:.2f} us")


# EXAMPLE USE:
# with Timer():
#     # Code block whose execution time you want to measure
#     for i in range(1000000):
#         pass
