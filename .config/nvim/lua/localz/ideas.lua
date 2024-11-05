-- use cmd line events to store history of cmdline and add undo/redo support?
-- use wilder as a reference to how to use the cmd line / change it / etc
-- could start with just the history for the current cmdline (clear on leave)
vim.cmd [[

function! CmdlineHistory_add(cmdline)
    "call luaeval("vim.notify('Current input: ' .. vim.inspect(vim.fn.getcmdline()))")
    if !exists('g:cmdline_history')
        let g:cmdline_history = []
    endif
    call add(g:cmdline_history, a:cmdline)
endfunction

function! CmdlineHistory_clear()
    let g:cmdline_history = []
endfunction

augroup cmdline_history
    autocmd!
    "autocmd CmdlineLeave * call CmdlineHistory_add(getcmdline())
    autocmd CmdlineChanged * call CmdlineHistory_add(getcmdline())
    autocmd CmdlineEnter * call CmdlineHistory_clear()
augroup END

]]

vim.keymap.set('c', '<C-z>', function()
    if vim.g.cmdline_history_index == nil then
        vim.g.cmdline_history_index = #vim.g.cmdline_history - 1
    elseif vim.g.cmdline_history_index > 0 then
        vim.g.cmdline_history_index = vim.g.cmdline_history_index - 1
    else
        vim.g.cmdline_history_index = #vim.g.cmdline_history
    end
    local last_cmd_line = vim.g.cmdline_history[vim.g.cmdline_history_index]
    vim.fn.setcmdline(last_cmd_line)
end)

vim.keymap.set('c', '<C-y>', function()
    if vim.g.cmdline_history_index == nil then
        vim.g.cmdline_history_index = 0
    elseif vim.g.cmdline_history_index < #vim.g.cmdline_history - 1 then
        vim.g.cmdline_history_index = vim.g.cmdline_history_index + 1
    else
        vim.g.cmdline_history_index = 0
    end
    local last_cmd_line = vim.g.cmdline_history[vim.g.cmdline_history_index]
    vim.fn.setcmdline(last_cmd_line)
end)
