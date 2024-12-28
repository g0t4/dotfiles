function restartNvim()
    hs.eventtap.keyStroke({}, "Escape")
    -- TODO can I use some sort of async/await syntax instead?
    hs.timer.doAfter(0.01, function()
        hs.eventtap.keyStrokes(":qa")
        hs.timer.doAfter(0.01, function()
            hs.eventtap.keyStroke({}, "Return")
            hs.timer.doAfter(0.01, function()
                hs.eventtap.keyStrokes("nvim")
                hs.timer.doAfter(0.01, function()
                    hs.eventtap.keyStroke({}, "Return")
                end)
            end)
        end)
    end)
end

-- *** check app when key is pressed:
function bindAppSpecificKey(appName, modifiers, key, callback)
    -- TODO try add/remove key combos when switching to/from the app? which is better... by binding F10 that means this runs a check every time F10 is used globally
    -- could easily add logic here to setup the add/rm impl
    hs.hotkey.bind(modifiers, key, function()
        local focusedApp = hs.application.frontmostApplication()
        if focusedApp and focusedApp:name() == appName then
            callback()
        end
    end)
end

-- todo pass app name array?
bindAppSpecificKey("Ghostty", {}, "f10", restartNvim)






-- *** add/remove keys when switching apps:
-- -- FYI chatgpt suggested this and it sounds reasonable to me (as long as it doesn't bog down switching apps)
-- --    this would be used instead of a global binding that runs every time in every app.. instead just register it while using a given app and remove it when switch to another app...
-- --    do some perf timing to see if either way even matters
-- --
-- local vimBindings = {
--     ["F10"] = restartNvim
-- }
-- local activeBindings = {}
--
-- local function activateBindings(appName)
--     if activeBindings[appName] then return end
--
--     if appName == "iTerm" or appName == "Ghostty" then -- Replace with your Vim app name
--         activeBindings[appName] = {}
--         for key, action in pairs(vimBindings) do
--             table.insert(activeBindings[appName], hs.hotkey.bind({}, key, action))
--         end
--     end
-- end
--
-- local function deactivateBindings(appName)
--     if activeBindings[appName] then
--         for _, hotkey in ipairs(activeBindings[appName]) do
--             hotkey:delete()
--         end
--         activeBindings[appName] = nil
--     end
-- end
--
-- -- load for current app on hammerspoon start (otherwise it won't be active until switching away/to it)
-- activateBindings(hs.application.frontmostApplication():name())
--
-- hs.application.watcher.new(function(appName, eventType)
--     if eventType == hs.application.watcher.activated then
--         activateBindings(appName)
--     elseif eventType == hs.application.watcher.deactivated or eventType == hs.application.watcher.terminated then
--         deactivateBindings(appName)
--     end
-- end):start()
