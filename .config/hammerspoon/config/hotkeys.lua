local log = require('devtools.logs.logger').universal()
local _ = require("config.helpers.underscore")

APPS = {
    ScreenPal = "ScreenPal",
    iTerm2 = "iTerm2",
}

-- TODO allow disabling keys when I enter text boxes in SOM... then I can do single letter keymaps or short sequences
--  just replay the chars if not supposed to intercept

-- TODO move other keymaps here as you want to define more app specific handlers...
--   AND register new keymaps here going forward...
--  'hotkey.*cmd.*["\']\w["\']'

local spal_keys = require("config.macros.screenpal").keys

local global_keys = {
    ["cmd_alt_ctrl|m"] = uielements_cmd_alt_ctrl_m
}

function handle_key(modifiers, key_char)
    local key_key = table.concat(modifiers, "_") .. "|" .. key_char
    hs.hotkey.bind(modifiers, key_char, function()
        local app = hs.application.frontmostApplication()
        if app:name() == APPS.ScreenPal and spal_keys[key_key] then
            spal_keys[key_key]()
            return
        end
        if not global_keys[key_key] then
            return
        end
        global_keys[key_key]()
    end)
end

all_keys = _.union(_.keys(spal_keys), _.keys(global_keys))

for _, key_str in pairs(all_keys) do
    local modifier_parts, key_char = key_str:match("^([^|]+)%|(.)$")
    if modifier_parts and key_char then
        local modifiers = {}
        for mod in string.gmatch(modifier_parts, "([^_]+)") do
            table.insert(modifiers, mod)
        end
        log:info("  register key", modifiers, key_char)
        handle_key(modifiers, key_char)
    end
end
