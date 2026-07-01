local log = require('devtools.logs.logger').universal()

APPS = {
    ScreenPal = "ScreenPal",
    iTerm2 = "iTerm2",
}

-- TODO allow disabling keys when I enter text boxes in SOM... then I can do single letter keymaps or short sequences
--  just replay the chars if not supposed to intercept

-- TODO move other keymaps here as you want to define more app specific handlers...
--   AND register new keymaps here going forward...
--  'hotkey.*cmd.*["\']\w["\']'

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
    local app = hs.application.frontmostApplication()
    if app:name() == APPS.ScreenPal then
        screenpal_cmd_alt_ctrl_m()
    else
        uielements_cmd_alt_ctrl_m()
    end
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
    local app = hs.application.frontmostApplication()
    if app:name() == APPS.ScreenPal then
        screenpal_cmd_alt_ctrl_r()
    end
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "L", function()
    local app = hs.application.frontmostApplication()
    if app:name() == APPS.ScreenPal then
        screenpal_cmd_alt_ctrl_l()
    end
end)
