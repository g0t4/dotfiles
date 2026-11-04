local focused, apps, contexts, callback
local function window(id, title)
    return {id = function() return id end, title = function() return title end,
        unminimize = function(self) self.restored = true end,
        focus = function(self) focused = self end}
end
local function app(pid, windows)
    return {pid = function() return pid end, allWindows = function() return windows end}
end
hs = {
    application = {runningApplications = function() return apps end},
    window = {focusedWindow = function() return focused end},
    json = {read = function(path) return contexts[tonumber(path:match('context%-(%d+)'))] end},
    keycodes = {map = {['`'] = 50}},
    eventtap = {event = {types = {keyDown = 10}}, new = function(_, fn)
        callback = fn
        return {start = function(self) return self end, stop = function() end}
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
assert(not cycle.cycle(1))
cycle.init()
local function key(flags, code)
    return callback({getFlags = function() return flags end, getKeyCode = function() return code or 50 end})
end
assert(not key({cmd = true})) -- Other applications retain their native shortcut.
focused = a
assert(not key({ctrl = true}))
assert(not key({cmd = true, alt = true}))
assert(not key({cmd = true}, 12))
contexts[3].pid = 3
assert(key({cmd = true, shift = true})); assert(focused == c)
assert(key({cmd = true})); assert(focused == a)
cycle.shutdown()
print('Pip Rot cross-process window cycling passed')
