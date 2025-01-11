import iterm2
import os
import sys
from pathlib import Path

# add parent dir to sys.path so reuse "package" is available
sys.path.append(str(Path(__file__).resolve().parent.parent))
from reuse.common import *


async def main(connection):
    # Get the current iTerm2 app
    app = await iterm2.async_get_app(connection)

    # Get the current window
    current_window = app.current_window
    if current_window is None:
        print("No current window found!")
        return

    # Get the currently focused tab and session
    current_tab = current_window.current_tab
    if current_tab is None:
        print("No current tab found!")
        return
    current_session = current_tab.current_session

    # Get font zoom level and profile of the current session
    profile = await current_session.async_get_profile()

    print(f"Current profile: {profile}")
    print(f"type(profile): {type(profile)}")

    local_copy = profile.local_write_only_copy
    print(f"local_copy: {local_copy}")
    # Open a new tab in the same window
    new_tab = await current_window.async_create_tab(profile_customizations=local_copy)

    # # Set the font zoom level of the new session to match the original
    # new_session = new_tab.current_session
    # if font_zoom is not None:
    #     await new_session.async_set_variable("fontSize", font_zoom)
    #
    # # Change the directory of the new session
    # target_directory = "/path/to/your/directory"  # Replace with your target directory
    # if os.path.isdir(target_directory):
    #     await new_session.async_send_text(f"cd {target_directory}\n")
    # else:
    #     print(f"Directory '{target_directory}' does not exist!")


# Run the main function
# iterm2.run_until_complete(main)
