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
Dump("ppt", ppt)

-- local pptInfo = hs.application.infoForBundleID("com.microsoft.PowerPoint") -- returns hs.application object
-- Dump("pptInfo", pptInfo) -- UTT infos, etc -- IIAC Info.plist(s) are used to make this


-- TODO? hs.application.find
