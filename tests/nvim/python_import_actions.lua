-- Requires: uv tool install basedpyright
-- nvim --clean --headless '+luafile tests/nvim/python_import_actions.lua'
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/.config/nvim')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local clients = {}
local ok, err = xpcall(function()
    require('plugins.completions.nvim_native.vim_lsp')
    -- Exercise the real Python config without starting unrelated servers.
    for name in pairs(vim.lsp._enabled_configs) do
        if name ~= 'basedpyright' then vim.lsp.enable(name, false) end
    end
    vim.fn.writefile({ 'value = Path(".")' }, root .. '/example.py')
    vim.cmd.edit(root .. '/example.py')
    vim.bo.filetype = 'python'
    assert(vim.wait(15000, function()
        clients = vim.lsp.get_clients({ bufnr = 0, name = 'basedpyright' })
        return #clients == 1 and clients[1].initialized
    end), 'Basedpyright did not attach')
    local client = clients[1]
    local diagnostics
    assert(vim.wait(15000, function()
        diagnostics = vim.diagnostic.get(0)
        for _, diagnostic in ipairs(diagnostics) do
            if diagnostic.code == 'reportUndefinedVariable' then return true end
        end
        return false
    end), 'missing undefined-name diagnostic')
    local context = {}
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.user_data and diagnostic.user_data.lsp then
            table.insert(context, diagnostic.user_data.lsp)
        end
    end
    local result = assert(client:request_sync('textDocument/codeAction', {
        textDocument = vim.lsp.util.make_text_document_params(),
        range = { start = { line = 0, character = 8 }, ['end'] = { line = 0, character = 12 } },
        context = { diagnostics = context, only = { 'quickfix' } },
    }, 15000))
    assert(not result.err, vim.inspect(result.err))
    local action
    for _, candidate in ipairs(result.result or {}) do
        if candidate.title:find('from pathlib import Path', 1, true) then action = candidate; break end
    end
    assert(action, 'missing pathlib import action: ' .. vim.inspect(result.result))
    if not action.edit then
        local resolved = assert(client:request_sync('codeAction/resolve', action, 15000))
        assert(not resolved.err, vim.inspect(resolved.err))
        action = resolved.result
    end
    assert(action.edit, 'import action has no edit')
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'):find(
        'from pathlib import Path', 1, true), 'import was not inserted')
    assert(vim.wait(15000, function()
        for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
            if diagnostic.code == 'reportUndefinedVariable' then return false end
        end
        return true
    end), 'undefined-name diagnostic remained after import')
    assert(#vim.lsp.get_clients({ bufnr = 0 }) == 1, 'duplicate Python servers attached')
    print('PASS Basedpyright import quick fix inserts pathlib.Path and clears undefined-name diagnostic')
end, debug.traceback)
for _, client in ipairs(clients) do client:stop(true) end
vim.fn.delete(root, 'rf')
if not ok then print(err); vim.cmd.cquit() else vim.cmd.qa({ bang = true }) end
