DEBUG = False


def log(msg):
    # FYI check Cmd+Alt+J to see iterm2 logs (script console), with this output
    if not DEBUG:
        return
    print(msg)
