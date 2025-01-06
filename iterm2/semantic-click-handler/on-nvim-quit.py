import iterm2
import json
import os
from timing import Timer
from logs import log


def get_session_id():
    iterm_session_id = os.environ.get("ITERM_SESSION_ID")
    if iterm_session_id is None:
        log("No session id, aborting...")
        return

    # FYI ITERM_SESSION_ID has two parts:
    #   wXtYpZ:session_id
    #   i.e. w0t0p0:1EB6FBA4-5980-4DE5-9638-76BA088787ED
    #   wX = window #
    #   tY = tab #
    #   pZ = pane #
    # I only need session_id right now

    return iterm_session_id.split(":")[1]


# TODO make sure nvim checks ENV VARS before calling this script or just check here?
async def on_nvim_quit_save_window_state(connection: iterm2.Connection):

    # with Timer():
    session_id = get_session_id()
    if session_id is None:
        log("No session id, aborting...")
        return

    app = await iterm2.async_get_app(connection)  # ~ 2.5ms
    if app is None:
        log("No current app, aborting...")
        return

    session = app.get_session_by_id(session_id)  # 3us
    if session is None:
        log("No session, aborting...")
        return

    window = session.window  # 5us
    if window is None:
        log("No window, aborting...")
        return

    # TMP set var for testing
    # await session.async_set_variable("user.workspace_root", "/Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles")
    # await session.async_set_variable("user.workspace_profile_path", "/Users/wes/.config/wes-iterm2/workspaces/1b833d1461faf13fbe9c1e6fcc42dac77803a88dda808cdbc89b51682d320d52/profile.json")

    workspace_root = await window.async_get_variable("user.workspace_root")  # 240us
    if workspace_root is None:
        log("No workspace root, aborting...")
        return

    workspace_profile_path = await window.async_get_variable("user.workspace_profile_path")  # 280us
    if workspace_profile_path is None:
        log("No workspace profile path, aborting...")
        return

    current_profile = await session.async_get_profile()  # 2ms

    grid_size = session.grid_size  # 1us

    cur_font = current_profile.normal_font  # 6us

    frame = await window.async_get_frame()  # 3ms
    # log(f"origin: {frame.origin}, size: {frame.size.height}height x {frame.size.width}width")

    save_profile = {
        "columns": grid_size.width,
        "rows": grid_size.height,
        "font": cur_font,
        "x": frame.origin.x,
        "y": frame.origin.y,
    }
    log(f"save_profile: {save_profile}")

    with open(workspace_profile_path, "w") as f:
        f.write(json.dumps(save_profile))


iterm2.run_until_complete(on_nvim_quit_save_window_state)
