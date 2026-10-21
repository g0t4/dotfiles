-- Temporary, opt-in diagnostics for stale native completion menus.
local M = {}
local active
local last_path

local function record(session, event, data)
    if active ~= session then return end
    if #session.events >= 10000 then
        session.dropped = session.dropped + 1
        return
    end
    data.event = event
    data.ms = (vim.uv.hrtime() - session.started) / 1e6
    session.events[#session.events + 1] = data
end

local function snapshot(session, event)
    if vim.api.nvim_get_current_buf() ~= session.buf then return end
    local info = vim.fn.complete_info({ 'mode', 'pum_visible', 'items', 'selected' })
    local items = {}
    for _, item in ipairs(info.items) do
        items[#items + 1] = {
            word = item.word, abbr = item.abbr, kind = item.kind,
            menu = item.menu, match = item.match,
            client_id = vim.tbl_get(item, 'user_data', 'nvim', 'lsp', 'client_id'),
        }
    end
    record(session, event, {
        line = vim.api.nvim_get_current_line(), cursor = vim.api.nvim_win_get_cursor(0),
        changedtick = vim.api.nvim_buf_get_changedtick(session.buf),
        mode = info.mode, visible = info.pum_visible, selected = info.selected, items = items,
    })
end

local function wrap(session, client)
    if session.clients[client.id] then return end
    local original = client.rpc.request
    local wrapped = function(method, params, callback, ...)
        if method ~= 'textDocument/completion' or active ~= session
            or params.textDocument.uri ~= vim.uri_from_bufnr(session.buf) then
            return original(method, params, callback, ...)
        end
        session.sequence = session.sequence + 1
        local sequence = session.sequence
        record(session, 'request', {
            sequence = sequence, client = client.name, client_id = client.id,
            params = vim.deepcopy(params),
            line = vim.api.nvim_buf_get_lines(session.buf, params.position.line,
                params.position.line + 1, false)[1],
            changedtick = vim.api.nvim_buf_get_changedtick(session.buf),
        })
        return original(method, params, function(err, result, ...)
            local items = {}
            if type(result) == 'table' then
                for _, item in ipairs(result.items or result) do
                    items[#items + 1] = {
                        label = item.label, filterText = item.filterText, kind = item.kind,
                        textEdit = item.textEdit, insertText = item.insertText,
                    }
                end
            end
            record(session, 'response', {
                sequence = sequence, client_id = client.id, error = err,
                isIncomplete = type(result) == 'table' and result.isIncomplete or false,
                items = items,
            })
            return callback(err, result, ...)
        end, ...)
    end
    session.clients[client.id] = { rpc = client.rpc, original = original, wrapped = wrapped }
    client.rpc.request = wrapped
end

function M.stop()
    local session = active
    if not session then return end
    snapshot(session, 'stop')
    active = nil
    vim.api.nvim_del_augroup_by_id(session.group)
    for _, client in pairs(session.clients) do
        if client.rpc.request == client.wrapped then client.rpc.request = client.original end
    end
    local dir = vim.fn.stdpath('state') .. '/completion-traces'
    vim.fn.mkdir(dir, 'p')
    last_path = dir .. '/' .. os.date('%Y%m%d-%H%M%S') .. '-' .. vim.uv.hrtime() .. '.jsonl'
    local lines = {}
    for _, event in ipairs(session.events) do lines[#lines + 1] = vim.json.encode(event) end
    lines[#lines + 1] = vim.json.encode({ event = 'summary', dropped = session.dropped })
    vim.fn.writefile(lines, last_path)
    vim.notify('Completion trace saved: ' .. last_path)
    return last_path
end

function M.start()
    if active then M.stop() end
    local session = {
        buf = vim.api.nvim_get_current_buf(), started = vim.uv.hrtime(),
        events = {}, clients = {}, sequence = 0, dropped = 0,
        group = vim.api.nvim_create_augroup('native_completion_trace', { clear = true }),
    }
    active = session
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = session.buf })) do wrap(session, client) end
    record(session, 'start', {
        file = vim.api.nvim_buf_get_name(session.buf), version = vim.version(),
        complete = vim.bo.complete, completefunc = vim.bo.completefunc,
        omnifunc = vim.bo.omnifunc, completeopt = vim.o.completeopt,
        autocomplete = vim.o.autocomplete, autocompletedelay = vim.o.autocompletedelay,
    })
    vim.api.nvim_create_autocmd('LspAttach', {
        group = session.group, buffer = session.buf,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client then wrap(session, client) end
        end,
    })
    vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP', 'CompleteChanged', 'CompleteDone', 'InsertLeave' }, {
        group = session.group, buffer = session.buf,
        callback = function(args) snapshot(session, args.event) end,
    })
    vim.api.nvim_create_autocmd('VimLeavePre', { group = session.group, callback = M.stop })
    vim.notify('Completion trace started for this buffer. Reproduce, then :CompletionTraceStop')
end

function M.setup()
    vim.api.nvim_create_user_command('CompletionTraceStart', M.start, {})
    vim.api.nvim_create_user_command('CompletionTraceStop', M.stop, {})
    vim.api.nvim_create_user_command('CompletionTraceOpen', function()
        if active then M.stop() end
        if not last_path then
            vim.notify('No completion trace captured in this session')
            return
        end
        vim.cmd('tabnew ' .. vim.fn.fnameescape(last_path))
    end, {})
end

return M
