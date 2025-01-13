-- require("helpers")
-- *** hs.application module => AFAICT this is akin to get app process from System Events? similar?
hs.application.defaultAppForUTI("mp4") -- returns bundle id, i.e.:
--     org.videolan.vlc


-- FYI
--     defaults domains | string split "," | grep -i "foo"
local vlc = hs.application.applicationsForBundleID("org.videolan.vlc") -- returns hs.application object
Dump(vlc)
-- FYI vlc will basically be empty table if no app instance is running
-- IF app running:
--    { <userdata 1> -- hs.application: VLC }
local ppt = hs.application.applicationsForBundleID("com.microsoft.PowerPoint") -- returns hs.application object
Dump("ppt", ppt) -- FYI so far... not showing ppt instance that is running... must be bundle id difference?
-- TODO how can I lookup bundle id of running apps?
-- local pptInfo = hs.application.infoForBundleID("com.microsoft.PowerPoint") -- returns hs.application object
-- Dump("pptInfo", pptInfo) -- UTT infos, etc -- IIAC Info.plist(s) are used to make this

-- IIUC use name in App Switcher
--   == open -a "foo"
-- hs.application.launchOrFocus("PowerPoint") -- DOES NOT WORK
-- hs.application.launchOrFocus("Microsoft PowerPoint") -- works
-- hs.application.launchOrFocus("vlc") -- works
-- local worked = hs.application.launchOrFocus("/Applications/Microsoft PowerPoint.app") -- WORKS too
-- Dump("worked", worked) -- false means no app found, else true for launch/focus

-- -- DERP ... doesn't return a name that works... lol for launchOrFocus... (at least not for ppt)
-- local nameForBundleID = hs.application.nameForBundleID("com.microsoft.PowerPoint") -- returns "PowerPoint"
-- Dump("nameForBundleID(com.microsoft.PowerPoint)", nameForBundleID)
-- local pathForBundleID = hs.application.pathForBundleID("com.microsoft.PowerPoint") -- returns "/Applications/Microsoft PowerPoint.app"
-- Dump("pathForBundleID(com.microsoft.PowerPoint)", pathForBundleID) -- "/Applications/Microsoft PowerPoint.app"

-- running apps:
local running = hs.application.runningApplications()
Dump("running", running)


-- TODO? hs.application.find
