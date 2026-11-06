-- Shared Python backend: literal argv throughout, with cancellable async searches.
local M = {}
local tasks = {}
local log = require('config.logs').launcher()
local root = os.getenv('HOME') .. '/repos/github/g0t4/dotfiles'

local function run(action, value, callback)
    local task
    task = hs.task.new(root .. '/.venv/bin/python', function(code, stdout, stderr)
        tasks[task] = nil
        if code ~= 0 or stderr ~= '' then log:error('File history:', code, stderr) end
        if callback then callback(code, stdout) end
    end, {root .. '/.config/xonsh/lib/wes_file_history.py', action, value})
    if not task then return nil end
    tasks[task] = true
    if not task:start() then
        tasks[task] = nil
        log:error('Could not start file history backend')
        return nil
    end
    return task
end

function M.search(query, searchId, callback)
    local cancelled = false
    local task = run('search', query, function(code, stdout)
        if cancelled then return end
        local results = {}
        local ok, entries = pcall(hs.json.decode, stdout)
        if code == 0 and ok and type(entries) == 'table' then
            for _, entry in ipairs(entries) do
                table.insert(results, {
                    text = entry.path:match('[^/]+$') or entry.path,
                    subText = entry.path:match('^(.+)/[^/]+$') or '',
                    path = entry.path,
                    image = hs.image.iconForFile(entry.path),
                })
            end
        end
        callback(searchId, results)
    end)
    if not task then callback(searchId, {}) end
    return function()
        cancelled = true
        if task and tasks[task] then task:terminate() end
    end
end

function M.open(path)
    local task
    task = hs.task.new('/usr/bin/open', function(code, _, stderr)
        tasks[task] = nil
        if code == 0 then
            run('record', path)
        else
            log:error('Could not open file:', path, stderr)
            hs.alert.show('Could not open file; see Hammerspoon console')
        end
    end, {'--', path})
    if task then
        tasks[task] = true
        if not task:start() then tasks[task] = nil end
    end
end

return M
