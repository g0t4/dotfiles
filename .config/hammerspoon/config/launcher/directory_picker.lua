local M = {}
local log = require('config.logs').hammerspoons()
local task, tap, hotkey
local timers = {}
local project = os.getenv('HOME') .. '/repos/github/g0t4/dotfiles/tools/pip-rot'

local function find(element, predicate, depth)
    if not element or depth < 0 then return nil end
    if predicate(element) then return element end
    for _, child in ipairs(element:attributeValue('AXChildren') or {}) do
        local found = find(child, predicate, depth - 1)
        if found then return found end
    end
end

function M.panel(app)
    if not app then return nil end
    local window = hs.axuielement.applicationElement(app):attributeValue('AXFocusedWindow')
    return find(window, function(element)
        local id = element:attributeValue('AXIdentifier')
        return id == 'save-panel' or id == 'open-panel'
    end, 4)
end

local function wait_for(check, done)
    local attempts = 0
    local timer
    timer = hs.timer.doEvery(0.05, function()
        attempts = attempts + 1
        local value = check()
        if value or attempts >= 40 then
            timer:stop()
            timers[timer] = nil
            if value then done(value) else hs.alert.show('Directory picker: dialog did not become ready') end
        end
    end)
    timers[timer] = true
end

function M.navigate(app, panel, path)
    if not panel:isValid() or hs.fs.attributes(path, 'mode') ~= 'directory' then
        hs.alert.show('Directory picker: original dialog or folder is no longer available')
        return
    end
    app:activate()
    panel:performAction('AXRaise')
    wait_for(function()
        local front = hs.application.frontmostApplication()
        return front and front:pid() == app:pid() and M.panel(app) == panel
    end, function()
        -- Only the Go to Folder sheet gets a Return; never the Save/Open button.
        hs.eventtap.keyStroke({'cmd', 'shift'}, 'g', 0)
        wait_for(function()
            if not panel:isValid() then return nil end
            local sheet = find(panel, function(e)
                return e:attributeValue('AXIdentifier') == 'GoToWindow'
            end, 3)
            return find(sheet, function(e)
                return e:attributeValue('AXIdentifier') == 'PathTextField'
            end, 2)
        end, function(field)
            local front = hs.application.frontmostApplication()
            if not front or front:pid() ~= app:pid() then return end
            field:setAttributeValue('AXValue', path)
            if field:attributeValue('AXValue') ~= path then
                hs.alert.show('Directory picker: could not set folder path')
                return
            end
            field:setAttributeValue('AXFocused', true)
            hs.eventtap.keyStroke({}, 'return', 0)
        end)
    end)
end

function M.show()
    if task then return end
    local origin = hs.application.frontmostApplication()
    local panel = M.panel(origin)
    task = hs.task.new('/opt/homebrew/bin/uv', function(code, stdout, stderr)
        task = nil
        if code ~= 0 then
            log:error('Directory picker failed:', code, stderr)
            hs.alert.show('Directory picker failed; see Hammerspoon console')
            return
        end
        if not stdout or stdout:match('^%s*$') then
            if origin then origin:activate() end
            return
        end
        local ok, result = pcall(hs.json.decode, stdout)
        if not ok or type(result) ~= 'table' or type(result.path) ~= 'string'
            or hs.fs.attributes(result.path, 'mode') ~= 'directory' then
            hs.alert.show('Directory picker returned an invalid folder')
            return
        end
        local action = result.action or 'use'
        if action == 'copy' then
            hs.pasteboard.setContents(result.path)
            if origin then origin:activate() end
            hs.alert.show('Copied folder path')
        elseif action == 'open' then
            require('config.launcher.pip_rot').open(result.path)
        elseif action == 'use' then
            if panel then M.navigate(origin, panel, result.path)
            else require('config.launcher.pip_rot').open(result.path) end
        else
            hs.alert.show('Directory picker returned an unknown action')
        end
    end, {'run', '--project', project, '--', 'python', project .. '/directory_picker.py'})
    if not task or not task:start() then
        task = nil
        hs.alert.show('Could not start directory picker')
    end
end

function M.shutdown()
    if task then task:terminate(); task = nil end
    if tap then tap:stop(); tap = nil end
    if hotkey then hotkey:delete(); hotkey = nil end
    for timer in pairs(timers) do timer:stop() end
    timers = {}
end

function M.init()
    if hotkey then return end
    hotkey = hs.hotkey.bind({'ctrl', 'alt'}, 'p', M.show)
    -- Leave Ctrl+P untouched in editors, terminals, and the picker itself.
    tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local flags = event:getFlags()
        if event:getKeyCode() ~= hs.keycodes.map.p or not flags.ctrl
            or flags.cmd or flags.alt or flags.shift then return false end
        if not M.panel(hs.application.frontmostApplication()) then return false end
        hs.timer.doAfter(0, M.show)
        return true
    end):start()
    local previous = hs.shutdownCallback
    hs.shutdownCallback = function()
        M.shutdown()
        if previous then previous() end
    end
end

return M
