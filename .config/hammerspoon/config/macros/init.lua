local M = {}

-- *** streamdeck Keyboard Maestro wrapper to catch errors and log them and rethrow for KM to show too ***
function StreamDeckKeyboardMaestroRunner(what)
    -- I want error in hammerspoon logs too
    -- I also like the notification from KM b/c that is immediately visible
    --   FYI AFAICT KM will use exit code to decide when to show for NOTIFICATIONS
    --   BUT, it seems to always show on ANY STDOUT if you choose window as the option in KM
    --   IOTW AFAICT I only wanna use notifications in KM for "output"
    -- then when I go to look into the issue I want HS logs
    --
    -- FYI w/o this its easy to think unhandled exceptions are being swallowed when its just KM not showing errors (b/c you said ignore results, rightly so b/c results all the time are annoying)... anyways use this to always log them)
    -- TODO can I just wire up something such that anyone that calls hs CLI, the errors are caught and logged... then I wouldn't need this
    --     anyone that calls hs CLI the errors will go to their CLI instance's STDOUT...
    --     thus wrap here to catch here too
    --
    -- anything printed/unhandled here is going to show in logs for hs CLI => only for KM notifications in the case of KM calling this
    xpcall(function()
        -- keep all parsing inside too so I catch those errors and show in HS logs too
        local func = load(what)
        if func == nil then
            error("failed to load: " .. what)
            return
        end
        func()
    end, function(errorMsg) print("error: ", errorMsg) end)
    -- TODO verify it still shows notification for KM?
end

require("config.macros.brave")
require("config.macros.fcpx")
require("config.macros.google-docs")
require("config.macros.msft_office")

return M
