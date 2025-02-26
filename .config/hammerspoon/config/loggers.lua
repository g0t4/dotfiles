--

local M = {}
local initialPrint = print
function M.muteCoreMessages()
    print = function(first, ...)
        local succeeded, skipThisEntry =
            xpcall(function()
                    -- filter out chatty messages
                    if first ~= nil and type(first) == "string" then
                        if first:match("^-- ") then
                            -- avoid overhead of multiple matches... and I wonder if I can just filter any messages with "--" on start
                            if first:match("^-- Some applications have alternate names which") then
                                return true
                            end
                            if first:match("^-- Loading extension:") then
                                -- error("FUUUU2") -- good for testing xpcall handler
                                return true
                            end
                            if first:match("^-- Loading Spoon:") then
                                return true
                            end
                        end
                    end
                    return false
                end,
                function(err)
                    initialPrint("UNEXPECTED failure in PRINT OVERRIDE, review your logic: ", err)
                end)
        -- print is brittle, especially overriding it (and w/ varargs)... catch failures and make error message EXPLICIT
        --   I wasted an hour I believe b/c sometimes this was failing while I was troubleshooting another issue...
        --   would've been nice to clearly see the issue..
        --   also I need to learn to read stacktraces more carefully, I always skim and jump into code before finding line #
        -- on failure, succeeded = false, skipThisEntry = error
        -- on success, succeded = true and then skipThisEntry has true/false for skipping the entry (based on return X inside xpcall)
        if succeeded and skipThisEntry then
            return
        end
        initialPrint(first, ...)
    end
end

function M.unmuteCoreMessages()
    print = initialPrint
end

local quietStartup = true

-- *** comment out to re-enable core messages
-- have to set this here b/c below when I use setLogLevel on modules, then the initial load will show too
if quietStartup then
    M.muteCoreMessages()
end

-- FYI levels:
--   1 to 5, or 'nothing', 'error', 'warning', 'info', 'debug', or 'verbose',

-- *** threshold for NEW LOGGERS:
-- print("initial hs.logger.defaultLogLevel", hs.logger.defaultLogLevel) => "warning" by default
-- hs.logger.defaultLogLevel = "error" -- threshold for new loggers

-- *** threshold for individual modules:
--   modules don't expose logger instance, but they do expose setting log level (common practice?)
if quietStartup then
    hs.hotkey.setLogLevel("error")
end
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

return M
