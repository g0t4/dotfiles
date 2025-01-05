import json
import os
import iterm2
from common import log


async def save_workspace_profile(connection):
    last_saved_profile_by_window = {}

    app = await iterm2.async_get_app(connection)
    if app is None:
        log("No current app, aborting...")
        return

    async with iterm2.LayoutChangeMonitor(connection) as mon:
        while True:
            # ! BASED ON THIS EXAMPLE: https://iterm2.com/python-api/examples/mrutabs2.html
            # FYI KEEP IN MIND, sizing/positioning of regular terminal windows is not considered here.. these are for only the nvim-window semantic handler windows (currently)
            await mon.async_get()
            # FYI layout doesn't encompass moving windows... would need separate monitor for that, not gonna spend tiem on that part now
            # TODO it would be nice just to cache the save_profile objects and lookup in memory (and change in memory too) and then when iterm closes, flush them to disk... would be much more performant than writing to the file every time... could use closing a session as signal to flush changes... though I should actually do perf tests before I worry much about this...
            for window in app.windows:
                workspace_profile_path = await window.async_get_variable("user.workspace_profile_path")
                if workspace_profile_path is None:
                    continue
                session = window.current_tab.current_session
                # set the window's sizing based solely on the currrent tab/sesssion...  usually only 1 b/c I don't intend for multiple tabs in nvim-window from semantic handler clicks
                if session is None:
                    log("No session, skipping...")
                    continue
                grid_size = session.grid_size
                cur_session_profile = await session.async_get_profile()
                if cur_session_profile is None:
                    log("No session profile, skipping...")
                    continue
                cur_font = cur_session_profile.normal_font
                save_profile = {
                    "columns": grid_size.width,
                    "rows": grid_size.height,
                    "font": cur_font,
                    # ! TODO SAVE POSITION TOO, otherwise I am getting confused about where the window should open!!! when it is moved and not resized that throws me off
                    # "x": ??
                    # "y": ??
                }
                # FOOOO bar
                # frame = await window.async_get_frame()
                # log(f"origin: {frame.origin}, size: {frame.size.height}height x {frame.size.width}width")
                # origin would give me position info... to save too... but then I'd need to listen for window position changes too.. yuck...
                # CRAP MOVING WINDOW DOESN'T TRIGGER LAYOUT CHANGE... ok so skip this part for now is fine then...
                # so the reason why the windows restored in prior positions was b/c current window had last position used... thus also why it felt like it was restoring values from other workspaces when it wasn't

                # TODO do last saved based on profile_path not window id.. that way if open new window in same dir... not fighting to save over each other
                #   FYI if two sep windows are opened... unpredictable as to which is used to save the profile (order is not deterministic) but I don't intend for this use case anyways so ignore this and honestly I think restoring either size would feel fine... PRN avoid thrashing to save over top of each other?
                last_saved_was = last_saved_profile_by_window.get(window.window_id)
                # PRN debounce changes? (i.e. when drag resizing window, or zoom in/out)... only look into if resize feels sluggish (drag resize)
                if last_saved_was is None or last_saved_was != save_profile:
                    if last_saved_was is None:
                        log("ensuring profile dir exists... s/b called once per window")
                        # 7ms... not enough to justify caching most likely but hey the dir should never be removed so leave it
                        os.makedirs(os.path.dirname(workspace_profile_path), exist_ok=True)  # can I cache that this exists... one less call then

                    with open(workspace_profile_path, "w") as f:
                        f.write(json.dumps(save_profile))
                    last_saved_profile_by_window[window.window_id] = save_profile
