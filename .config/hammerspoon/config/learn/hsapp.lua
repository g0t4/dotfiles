-- require("helpers")
-- *** hs.application module => AFAICT this is akin to get app process from System Events? similar?
hs.application.defaultAppForUTI("mp4") -- returns bundle id, i.e.:
--     org.videolan.vlc


local vlc = hs.application.applicationsForBundleID("org.videolan.vlc") -- returns hs.application object
print("vlc app from bundle id", vlc)
Dump(vlc)
DumpWithMetatables(vlc)
Dump("foo")
-- hs.inspect.inspect(vlc, { metatables = true })

-- TODO? hs.application.find

--
