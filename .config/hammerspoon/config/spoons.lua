--
-- *** load spoons from the repo so I can clone and update it using git and not one by one "install"
--    wcl Hammerspoon/Spoons   # install/update spoons :)
--    alternatively use spoonInstall?
--    I did a diff of AClock and Source/AClock.spoon and it matched, maybe others won't?
--    FYI timing wise, didn't seem to add any penalty to this init.lua performance (one concern I had was impact on resolving modules)
local spoons_repo = os.getenv("HOME") .. "/repos/github/Hammerspoon/Spoons/Source/?.spoon/init.lua"
package.path = package.path .. ";" .. spoons_repo

-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
--     hs.loadSpoon("AClock")
--     spoon.AClock:toggleShow()
-- end)

-- *** FUUU, ask-openai (in devtools only - B shortcut) isn't working if I comment this out:
-- -- THEN, when I uncomment this and reload hammerspoon's config, ask-open starts working again in devtools
-- -- AND, if I comment this out again and reload config,  relaunch, even quity/start (restart) hammerspoon, it works still
-- --   AS If the first load of these spoons fixes the issue... IIAC after reboot it won't work again
-- --   INEVITABLY though it stops working again (IIGC after machine reboot) - todo check restart/logout and see if repro
-- --   FIX WHEN I CAN RELIABLY REPRO this... IIRC I could get it to repro across reload configs, so I might need to do some more testing on that
-- -- FYI if I wanna keep this spoon, I could nest it inside a hotkey like AClock above and invoke without using its bindHotKeys function
-- --
-- hs.loadSpoon("Emojis") -- SUPER SLOW
-- spoon.Emojis:bindHotkeys({
--     toggle = {
--         { "cmd", "alt", "ctrl" },
--         "J",
--     }
-- })

-- *** EmmyLua generate stubs for hs.* modules
-- - first run takes a second to generate stubs
-- - also if outdated, IIAC on file timestamps?
-- - based on discussion in:
--   - https://github.com/Hammerspoon/hammerspoon/pull/2530
--   - https://github.com/Hammerspoon/Spoons/pull/240
-- PRN could set a script that runs automatically when neovim starts in just my hammerspoon config dir
print("loading EmmyLua to generate stubs if needed... can do this manually if this is too slow here as I only need this for neovim lua LS... not for hammerspoon app itself")
hs.loadSpoon("EmmyLua") -- <2ms to check is fine... NBD to run all the time
