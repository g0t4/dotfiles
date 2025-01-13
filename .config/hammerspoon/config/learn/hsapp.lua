-- require("helpers")
-- *** hs.application module => AFAICT this is akin to get app process from System Events? similar?
hs.application.defaultAppForUTI("mp4") -- returns bundle id, i.e.:
--     org.videolan.vlc


local vlc = hs.application.applicationsForBundleID("org.videolan.vlc") -- returns hs.application object
Dump(vlc)
-- FYI vlc will basically be empty table if no app instance is running
-- IF app running:
--    { <userdata 1> -- hs.application: VLC }

-- TODO? hs.application.find
