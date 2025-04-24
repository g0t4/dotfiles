    vim.cmd [[
"
" TODO review/modify this? I haven't yet taken time to understand and think through this for changes...

" OMG this is FAST!!!
" verbatim copied from: https://github.com/neovim/neovim/issues/12428

" BUT has some issues... Ctrl+P is selecting items when unique keys typed... show w/o select?
function! OnCompletionDone(timer) abort
        let g:doing_update = 0
endfunction

function! OnTimeoutTriggered(timer) abort
        if pumvisible()
                call nvim_input('<C-p>')
        endif
        call timer_start(5, 'OnCompletionDone')
endfunction

function! OnCmdlineChanged() abort
        if !exists('g:doing_update') || !g:doing_update
                let g:doing_update = 1
                call nvim_input('<C-n>')
                call timer_start(5, 'OnTimeoutTriggered')
        endif
endfunction

set wildchar=<C-n>
au CmdlineChanged * call OnCmdlineChanged()
        ]]

