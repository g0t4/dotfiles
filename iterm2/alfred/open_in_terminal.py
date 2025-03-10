import iterm2
import os
import sys
from common import *


async def main(connection):
    # args
    to_dir = sys.argv[1]
    print(f"to_dir: {to_dir}")
    if not os.path.isdir(to_dir):
        print(f"Directory '{to_dir}' does not exist!")
        return 1

    current_window = await get_current_window(connection)
    if current_window is None:
        print("No current window found!")
        return

    current_session = await get_current_session(connection)
    if current_session is None:
        print("No current session found!")
        return

    # Get font zoom level and profile of the current session
    profile = await current_session.async_get_profile()
    new_profile = profile.local_write_only_copy

    new_profile.set_custom_directory(to_dir)
    new_profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_CUSTOM)

    new_tab = await current_window.async_create_tab(profile_customizations=new_profile)

    #   PRN I could add something to detect if option is heldd down and then not do this
    await bring_iterm_to_front(connection)


# Run the main function
iterm2.run_until_complete(main)
