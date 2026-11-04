-- Treat independent Pip Rot processes as one family for window cycling.
local M = {}
local tap
local suffix = ' — Pip Rot'

function M.windows()
    local windows = {}
    for _, app in ipairs(hs.application.runningApplications()) do
        local context
        for _, window in ipairs(app:allWindows()) do
            local title = window:title() or ''
            if title:sub(-#suffix) == suffix then
                if context == nil then
                    context = hs.json.read(os.getenv('HOME') .. '/.local/state/pip-rot/context-'
                        .. app:pid() .. '.json') or false
                end
                if type(context) == 'table' and context.version == 1
                    and context.source == 'pip-rot' and context.pid == app:pid()
                    and context.window_title == title then
                    table.insert(windows, window)
                end
            end
        end
    end
    -- Focus changes must not reorder the ring (MRU order would bounce between two).
    table.sort(windows, function(a, b) return a:id() < b:id() end)
    return windows
end

function M.cycle(direction)
    local focused = hs.window.focusedWindow()
    if not focused then return false end
    local windows = M.windows()
    for index, window in ipairs(windows) do
        if window:id() == focused:id() then
            local target = windows[(index - 1 + direction) % #windows + 1]
            if target:id() ~= focused:id() then
                target:unminimize()
                target:focus()
            end
            return true
        end
    end
    return false
end

function M.shutdown()
    if tap then tap:stop(); tap = nil end
end

function M.init()
    if tap then return end
    tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local flags = event:getFlags()
        if event:getKeyCode() ~= hs.keycodes.map['`'] or not flags.cmd
            or flags.ctrl or flags.alt then return false end
        return M.cycle(flags.shift and -1 or 1)
    end):start()
    local previous = hs.shutdownCallback
    hs.shutdownCallback = function()
        M.shutdown()
        if previous then previous() end
    end
end

return M
