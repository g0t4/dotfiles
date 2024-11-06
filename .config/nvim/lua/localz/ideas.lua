-- !!! SUPER BUGGY, just spitballing ideas

function cmdline_enter()
    _G.cmdline_history = {}
    _G.cmdline_history_index = -1
    _G.cmdline_last_cmdline = ''
end

function cmdline_changed()
    local cmdline = vim.fn.getcmdline()

    if cmdline == _G.cmdline_last_cmdline then
        return
    end

    -- find first difference between cmdline and last_cmdline, just to test spaces as delimiter
    local index = 0
    while index < #cmdline and index < #_G.cmdline_last_cmdline do
        if cmdline:sub(index + 1, index + 1) ~= _G.cmdline_last_cmdline:sub(index + 1, index + 1) then
            break
        end
        index = index + 1
    end
    local diff_cmdline = cmdline:sub(index + 1, index + 1)
    local diff_last_cmdline = _G.cmdline_last_cmdline:sub(index + 1, index + 1)

    if diff_cmdline == ' ' then
        -- add to history
        table.insert(_G.cmdline_history, cmdline)
        _G.cmdline_history_index = #_G.cmdline_history
        _G.cmdline_last_cmdline = cmdline
        return
    end
    -- vim.notify('diff_cmdline: ' .. diff_cmdline)
    _G.cmdline_last_cmdline = cmdline

    -- TODO what happens when pull back old command? just need to add it right? but in that case first diff isn't a space
    -- TODO more cases here for deleting spaces
    -- TODO handle edits mid-cmdline (if needed, need to make test cases)
end

vim.api.nvim_create_augroup('cmdline_history', { clear = true })

vim.api.nvim_create_autocmd('CmdlineChanged', {
    group = 'cmdline_history',
    callback = cmdline_changed,
})

vim.api.nvim_create_autocmd('CmdlineEnter', {
    group = 'cmdline_history',
    callback = cmdline_enter,
})

-- *** undo
vim.keymap.set('c', '<C-z>', function()
    if _G.cmdline_history_index == nil then
        _G.cmdline_history_index = #_G.cmdline_history - 1
    elseif _G.cmdline_history_index > 0 then
        _G.cmdline_history_index = _G.cmdline_history_index - 1
    else
        return
    end
    local last_cmd_line = _G.cmdline_history[_G.cmdline_history_index]
    if last_cmd_line == nil then
        vim.fn.setcmdline('')
        return
    end
    vim.fn.setcmdline(last_cmd_line)
end)

-- *** redo
vim.keymap.set('c', '<C-y>', function()
    if _G.cmdline_history_index == nil then
        return -- nothing to redo until after first undo
    elseif _G.cmdline_history_index < #_G.cmdline_history - 1 then
        _G.cmdline_history_index = _G.cmdline_history_index + 1
    else
        return
    end
    local last_cmd_line = _G.cmdline_history[_G.cmdline_history_index]
    if last_cmd_line == nil then
        vim.fn.setcmdline('')
        return
    end
    vim.fn.setcmdline(last_cmd_line)
end)

function Watch_cmdline()
    start_watching(function()
        return _G.cmdline_history
    end)
end
