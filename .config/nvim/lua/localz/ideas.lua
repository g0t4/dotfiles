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

" FYI eCmdlineHistory_prev shows up as CmdlineChanged events as its typed out... yikez
cmap <C-u> <C-\>eCmdlineHistory_prev()<CR>
cmap <C-n> <C-\>eCmdlineHistory_next()<CR>

function! CmdlineHistory_prev()
    "return g:cmdline_history[len(g:cmdline_history) - 1]
    return "replace with undone cmdline"
endfunction
]]
