DEBUG = True

# TODO make debug toggleable? OR better yet use a logging library

# log should take one or more args like print
def log(*args):
    # FYI check Cmd+Alt+J to see iterm2 logs (script console), with this output
    if not DEBUG:
        return
    print(*args)
