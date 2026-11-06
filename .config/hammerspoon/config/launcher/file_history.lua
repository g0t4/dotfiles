-- Shared Python backend: literal argv throughout, with cancellable async searches.
local M = {}
local tasks = {}
local log = require('config.logs').launcher()
local root = os.getenv('HOME') .. '/repos/github/g0t4/dotfiles'

local function run(action, value, callback)
    local task
    local args = {root .. '/.config/xonsh/lib/wes_file_history.py', action, value}
    if action == 'record' then
        table.insert(args, '--source'); table.insert(args, 'launcher')
    end
    task = hs.task.new(root .. '/.venv/bin/python', function(code, stdout, stderr)
        tasks[task] = nil
        if code ~= 0 or stderr ~= '' then log:error('File history:', code, stderr) end
        if callback then callback(code, stdout) end
    end, args)
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

local inspector = nil

local function escape(value)
    return tostring(value or ''):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'):gsub("'", '&#39;')
end

local function date(value)
    if not value then return 'Unknown' end
    return os.date('%Y-%m-%d %H:%M:%S %Z', math.floor(value))
end

function M.inspectorHTML(entry)
    local html = {[[<!doctype html><meta charset="utf-8"><style>
    :root {color-scheme:dark} body {font:14px -apple-system,sans-serif;line-height:1.5;background:#202124;color:#eee;padding:20px;max-width:850px;margin:auto}
    h1 {font-size:22px;margin:0} h2 {font-size:16px;margin-top:24px;color:#aad4ff}
    .path {white-space:pre-wrap;overflow-wrap:anywhere;color:#bbb} .status {font-weight:600}
    table {border-collapse:collapse;width:100%} td {padding:5px 8px;border-bottom:1px solid #393b40;vertical-align:top;white-space:pre-wrap;overflow-wrap:anywhere}
    td:first-child {color:#bbb;width:165px} .note {color:#bbb;font-size:12px} </style>]]}
    local function add(value) table.insert(html, value) end
    local function row(label, value) add('<tr><td>' .. escape(label) .. '</td><td>' .. escape(value) .. '</td></tr>') end
    local fs = entry.filesystem or {}
    add('<h1>' .. escape(entry.path:match('[^/]+$') or entry.path) .. '</h1>')
    add('<p class="path">' .. escape(entry.path) .. '</p>')
    add('<p class="status">' .. escape(fs.status) .. ' · ' .. escape(entry.normal_search) .. '</p>')
    if fs.reason then add('<p>' .. escape(fs.reason) .. '</p>') end
    add('<h2>Why it is remembered</h2>')
    if #entry.sources == 0 then add('<p>No history entry. This path was supplied explicitly.</p>') end
    for _, source in ipairs(entry.sources) do
        add('<p><b>' .. escape(source.source) .. '</b><br>' .. escape(source.reason) .. '</p><table>')
        row('Store', source.database)
        if source.opens then row('Accepted opens', source.opens); row('Last opened', date(source.last_open)) end
        if source.rank then row('z rank', source.rank); row('Last directory visit', date(source.last_visit)) end
        row('Usage score', string.format('%.4f', source.usage_score or 0))
        for _, origin in ipairs(source.recorded_by or {}) do
            row('Recorded by', origin.source .. ': ' .. origin.opens .. ' opens' .. (origin.last_open and (' · last ' .. date(origin.last_open)) or ''))
        end
        add('</table>')
    end
    add('<h2>Filesystem now</h2><table>'); row('Inspected at', date(entry.inspected_at))
    if fs.symlink_target then row('Symlink target', fs.symlink_target) end
    if fs.kind then
        row('Type', fs.kind); row('Size (stat)', fs.size .. ' bytes')
        row('Permissions', fs.permissions); row('Owner UID / GID', fs.uid .. ' / ' .. fs.gid)
        row('Created', date(fs.created)); row('Modified', date(fs.modified))
        row('Metadata changed', date(fs.metadata_changed)); row('Accessed (stat)', date(fs.accessed))
    end
    add('</table><h2>Search diagnostics</h2><table>'); row('Match score', entry.match_score); add('</table>')
    add('<p class="note">' .. escape(entry.note) .. '</p>')
    for _, warning in ipairs(entry.warnings or {}) do add('<p>' .. escape(warning) .. '</p>') end
    add('<p class="note">Read-only inspection. Escape closes this window.</p>')
    return table.concat(html)
end

function M.inspect(entry)
    if inspector then inspector:delete(); inspector = nil end
    local frame = hs.screen.mainScreen():frame()
    local w, h = math.min(850, frame.w - 80), math.min(760, frame.h - 80)
    local view
    view = hs.webview.new({x=frame.x+(frame.w-w)/2, y=frame.y+(frame.h-h)/2, w=w, h=h})
        :windowStyle({'titled', 'closable', 'resizable'})
        :windowTitle('File history · ' .. (entry.path:match('[^/]+$') or entry.path))
        :allowTextEntry(true):closeOnEscape(true):deleteOnClose(true)
        :windowCallback(function(action) if action == 'closing' and inspector == view then inspector = nil end end)
        :html(M.inspectorHTML(entry)):show()
    inspector = view
    inspector:hswindow():focus()
    return inspector
end

function M.info(query, searchId, callback)
    local cancelled = false
    local task = run('info', query, function(code, stdout)
        if cancelled then return end
        local results = {}
        local ok, report = pcall(hs.json.decode, stdout)
        if code == 0 and ok and type(report) == 'table' then
            for _, entry in ipairs(report.entries or {}) do
                entry.note, entry.warnings = report.note, report.warnings
                local sources = {}
                for _, source in ipairs(entry.sources) do table.insert(sources, source.source) end
                table.insert(results, {
                    text = (entry.path:match('[^/]+$') or entry.path) .. ' · ' .. entry.filesystem.status,
                    subText = entry.path .. ' · ' .. (#sources > 0 and table.concat(sources, ', ') or 'Not tracked') .. ' · Return to inspect',
                    diagnostic = entry,
                    image = hs.image.imageFromName('NSInfo'),
                })
            end
            if #results == 0 then table.insert(results, {text='No remembered paths match', subText='Try info /absolute/path to inspect any path'}) end
            if report.matches > #(report.entries or {}) then
                table.insert(results, {text='Showing ' .. #(report.entries or {}) .. ' of ' .. report.matches .. ' matches', subText='Narrow the query to inspect more specific paths'})
            end
            for _, warning in ipairs(report.warnings or {}) do table.insert(results, {text='History unavailable', subText=warning}) end
        else
            table.insert(results, {text='Could not read history diagnostics', subText='See Hammerspoon console'})
        end
        callback(searchId, results)
    end)
    if not task then callback(searchId, {{text='Could not start history diagnostics'}}) end
    return function()
        cancelled = true
        if task and tasks[task] then task:terminate() end
    end
end

function M.closeInspector()
    if inspector then inspector:delete(); inspector = nil end
end

return M
