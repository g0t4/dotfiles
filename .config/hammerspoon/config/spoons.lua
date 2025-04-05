--
-- *** load spoons from the repo so I can clone and update it using git and not one by one "install"
--    wcl Hammerspoon/Spoons   # install/update spoons :)
--    alternatively use spoonInstall?
--    FYI timing wise, didn't seem to add any penalty to this init.lua performance (one concern I had was impact on resolving modules)
local spoons_repo = os.getenv("HOME") .. "/repos/github/Hammerspoon/Spoons/Source/?.spoon/init.lua"
package.path = package.path .. ";" .. spoons_repo

-- *** FUUU, ask-openai (in devtools only - B shortcut) isn't working if I comment this out:
-- -- THEN, when I uncomment this and reload hammerspoon's config, ask-open starts working again in devtools
-- -- AND, if I comment this out again and reload config,  relaunch, even quity/start (restart) hammerspoon, it works still
-- --   AS If the first load of these spoons fixes the issue... IIAC after reboot it won't work again
-- --   INEVITABLY though it stops working again (IIGC after machine reboot) - todo check restart/logout and see if repro
-- --   FIX WHEN I CAN RELIABLY REPRO this... IIRC I could get it to repro across reload configs, so I might need to do some more testing on that


function UpdateSpoonsRepo()
    -- pull latest on spoons repo
    -- TODO if needed, why not make a method that does this => run cmd, dump output and nothing fancy... just pass a cmd and it does rest (executeAndLog)
    local output, status, type, rc = hs.execute("/usr/bin/env fish --no-config -c 'cd $HOME/repos/github/Hammerspoon/Spoons && git pull'", true)
    if output ~= nil or output ~= "" then
        -- FYI OSC codes are printed, its fine
        print("STDOUT:" .. tostring(output))
    end
    if rc ~= 0 then
        print("Exit code: " .. status)
        print("Type:      " .. type)
    end
end
