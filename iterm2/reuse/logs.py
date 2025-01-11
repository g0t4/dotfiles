DEBUG = True


# log should take one or more args like print
def log(*args):
    # FYI check Cmd+Alt+J to see iterm2 logs (script console), with this output
    if not DEBUG:
        return
    print(*args)
