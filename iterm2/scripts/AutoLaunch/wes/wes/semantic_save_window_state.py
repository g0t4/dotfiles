import os
import time
import iterm2
import json
import traceback
# from timing import Timer
from logs import log


async def on_nvim_quit_save_window_state(connection: iterm2.Connection, session_id):

    if session_id is None:
        log("No session id, aborting...")
        return
    session_id = session_id.strip()
    if ":" in session_id:
        # so I can pass ITERM_SESSION_ID env var verbatim in clients (or not)
        # simplifies client code to handle this here
        session_id = session_id.split(":")[1]

    log(f"session_id: {session_id}")

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

    workspace_root = await window.async_get_variable("user.workspace_root")  # 240us
    if workspace_root is None:
        log("No workspace root, aborting...")
        return

    workspace_profile_path = await window.async_get_variable("user.workspace_profile_path")  # 280us
    if workspace_profile_path is None:
        log("No workspace profile path, aborting...")
        return

    log(f"workspace_root: {workspace_root}")
    log(f"workspace_profile_path: {workspace_profile_path}")

    current_profile = await session.async_get_profile()  # 2ms

    grid_size = session.grid_size  # 1us

    cur_font = current_profile.normal_font  # 6us

    try:
        frame = await window.async_get_frame()  # 3ms
    except iterm2.GetPropertyException as e:
        # CONFIRMED WINDOW IS NO LONGER VISIBLE HERE... why is the client not blocking for this!?
        # PRN just save w/o frame?
        stack = traceback.format_exc()
        log(f"GetPropertyException on window.async_get_frame() => {stack}")
        log(f" start sleeping, is window gone?")
        time.sleep(10)
        log(f" end sleeping")
        return

        # TODO TRYING AGAIN to see if this fixes it?
        # PRN ADD SLEEP HERE TO SEE IF WINDOW IS ALREADY GONE MAYBE?

    # log(f"origin: {frame.origin}, size: {frame.size.height}height x {frame.size.width}width")

    save_profile = {
        "columns": grid_size.width,
        "rows": grid_size.height,
        "font": cur_font,
        "x": frame.origin.x,
        "y": frame.origin.y,
    }

    # PRN can send DONE (to client) here, before saving profile.json (if needed for an actual lag issue, else leave as is for simplicity)
    log(f"save_profile: {save_profile}")

    os.makedirs(os.path.dirname(workspace_profile_path), exist_ok=True)
    with open(workspace_profile_path, "w") as f:
        f.write(json.dumps(save_profile))
