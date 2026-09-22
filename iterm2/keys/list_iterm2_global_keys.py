import iterm2
import rich

async def main(connection):
    app = await iterm2.async_get_app(connection)
    session = app.current_terminal_window.current_tab.current_session
    profile = await session.async_get_profile()

    # maps = profile.key_mappings.items()
    # rich.print(maps)
    # print()
    # for key, value in maps:
    #     rich.print(key, "=>", value)
    #     rich.print(type(key))
    #     rich.print(type(value))
    #     binding = iterm2.decode_key_binding(key, value)
    #     rich.print(binding)
    # # profile.async_set_key_mappings()

    # * global keymaps (Settings => Keys)
    binding = await iterm2.async_get_global_key_bindings(connection)
    for action in binding:
        rich.print(action)
        rich.print(type(action))

iterm2.run_until_complete(main)

