local focused, apps, contexts, callback, activation, frontApp
local scans, tapping, watching = 0, false, false
local function window(id, title)
    return {id = function() return id end, title = function() return title end,
        unminimize = function(self) self.restored = true end,
        focus = function(self) focused = self end}
end
local function app(pid, windows)
    return {pid = function() return pid end, allWindows = function() return windows end,
        focusedWindow = function() return focused end, bundleID = function() return 'python' end}
end
hs = {
    application = {runningApplications = function() scans = scans + 1; return apps end,
        frontmostApplication = function() return frontApp or app(4, {focused}) end,
        watcher = {activated = 1, deactivated = 2, new = function(fn)
            activation = fn
            return {start = function(self) watching = true; return self end,
                stop = function() watching = false end}
        end}},
    window = {focusedWindow = function() return focused end},
    json = {read = function(path) return contexts[tonumber(path:match('context%-(%d+)'))] end},
    keycodes = {map = {['`'] = 50}},
    eventtap = {event = {types = {keyDown = 10}}, new = function(_, fn)
        callback = fn
        return {start = function(self) tapping = true; return self end, stop = function() tapping = false end}
    end},
}
local cycle = dofile('.config/hammerspoon/config/launcher/pip_rot_windows.lua')
local a, b, c = window(10, '/a — Pip Rot'), window(20, '/b — Pip Rot'), window(30, '/c — Pip Rot')
local unrelated = window(40, 'Editor')
local impostor = window(50, '/fake — Pip Rot')
contexts = {}
for pid, w in ipairs({a, b, c}) do
    contexts[pid] = {version = 1, source = 'pip-rot', pid = pid, window_title = w:title()}
end
apps = {app(3, {c}), app(1, {a}), app(4, {unrelated, impostor}), app(2, {b})}
focused = a
for _, expected in ipairs({b, c, a}) do
    assert(cycle.cycle(1)); assert(focused == expected); assert(expected.restored)
end
assert(cycle.cycle(-1)); assert(focused == c)
-- Closed windows disappear, and a stale identity cannot enroll another process.
apps = {app(1, {a}), app(3, {c}), app(4, {impostor})}
assert(cycle.cycle(1)); assert(focused == a)
contexts[3].pid = 999
assert(#cycle.windows() == 1)
assert(cycle.cycle(1)); assert(focused == a)
focused = unrelated
local before = scans
assert(not cycle.cycle(1))
assert(scans == before, 'other apps must never trigger window enumeration')
cycle.init()
assert(watching and not tapping, 'hook must be stopped when initialized outside Pip Rot')
local function key(flags, code)
    return callback({getFlags = function() return flags end, getKeyCode = function() return code or 50 end})
end
assert(not key({cmd = true})) -- Other applications retain their native shortcut.
assert(scans == before, 'native shortcut must pass through without scanning')
focused = a
activation('Python', hs.application.watcher.activated, app(1, {a}))
assert(tapping, 'source-launched Pip Rot should enable the hook')
assert(not key({ctrl = true}))
assert(not key({cmd = true, alt = true}))
assert(not key({cmd = true}, 12))
contexts[3].pid = 3
assert(key({cmd = true, shift = true})); assert(focused == c)
assert(key({cmd = true})); assert(focused == a)
-- A late deactivation of the previous app must not disable the active Pip Rot hook.
activation('Editor', hs.application.watcher.deactivated, app(4, {unrelated}))
assert(tapping, 'late deactivation must reconcile the current front app')
focused = unrelated
activation('Python', hs.application.watcher.deactivated, app(1, {a}))
assert(not tapping)
activation('Editor', hs.application.watcher.activated, app(4, {unrelated}))
assert(not tapping, 'other apps must leave the hook stopped')
frontApp = {
    focusedWindow = function() return nil end,
    bundleID = function() return 'com.g0t4.pip-rot' end,
}
activation('Pip Rot', hs.application.watcher.activated, frontApp)
assert(tapping, 'bundle activation should work before its window gains focus')
cycle.shutdown()
assert(not tapping and not watching)
print('Pip Rot cross-process window cycling passed')
