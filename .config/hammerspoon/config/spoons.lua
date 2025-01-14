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
--
-- OK so ask-openai works fine now w/o this spoon... BUT FOR A WHILE, ask-openai (B shortcut) wasn't working w/o this loaded too, some dependency issue? or timing?
-- hs.loadSpoon("Emojis") -- SUPER SLOW
-- spoon.Emojis:bindHotkeys({
--     toggle = {
--         { "cmd", "alt", "ctrl" },
--         "E",
--     }
-- })
