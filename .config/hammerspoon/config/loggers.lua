--





-- FYI levels:
--   1 to 5, or error, warning, info, debug, trace - or "nothing"
--   TODO confirm "nothing" works

-- *** threshold for NEW LOGGERS:
print("initial hs.logger.defaultLogLevel", hs.logger.defaultLogLevel)
-- hs.logger.defaultLogLevel = "error" -- threshold for new loggers

-- *** threshold for individual modules:
--   modules don't expose logger instance, but they do expose setting log level (common practice?)
hs.hotkey.setLogLevel("error")
-- TODO OTHER MODULES that are TOO VERBOSE (search hammerspoon repo)

-- *** set threshold for all loggers (modules and instances):
-- hs.logger.setGlobalLogLevel("debug")

-- *** set threshold for modules only:
-- hs.logger.setModulesLogLevel("error")

-- *** custom loggers:
-- local myLog = hs.logger.new("myLog", "error") -- only log errors
-- myLog.i("from myLog infoing")
-- FYI logs that are printed to console will still have timestamp from printing them...
--   and that means double timestamps if you use logger and it prints to console
--   that's why internally I see use of .f() to avoid double timestamps and even showing level it seems
-- myLog.d("from myLog debugging")
-- myLog.e("from myLog erroring")
-- myLog.ef("foo: %s", "from myLog ef-ing")
-- myLog.f("foo: %s", "from myLog f-ing") -- override entire log output format (i.e. timestamp, level, etc)
