local use_vimspector = true
if not use_vimspector then
    return {}
end

return {

    {
        'puremourning/vimspector',
        config = function()
            -- articles to read/try:
            -- - https://puremourning.github.io/vimspector-web/demo-setup.html
            -- - https://dev.to/iggredible/debugging-in-vim-with-vimspector-4n0m
            -- reference: https://puremourning.github.io/vimspector/
            -- schemas: https://puremourning.github.io/vimspector/schema/

            -- FYI, later port to lua if useful to do so
            vim.cmd [[
                " todo turn this off and see what difference it makes once debugging is working
                "let g:vimspector_enable_mappings = 'HUMAN'
                " TODO keys to consider: https://puremourning.github.io/vimspector-web/#debugging

                " always map these:
                nmap <F5> <Plug>VimspectorLaunch

                " alternatives to mouse hover which isn't likely gonna work in terminals (nor in nvim IIUC)
                nmap <Leader>di <Plug>VimspectorBalloonEval
                xmap <Leader>di <Plug>VimspectorBalloonEval

                " Custom mappings while debugging {{{
                let s:mapped = {}

                function! s:OnJumpToFrame() abort
                  if has_key( s:mapped, string( bufnr() ) )
                    return
                  endif

                  nmap <silent> <buffer> <LocalLeader>dn <Plug>VimspectorStepOver
                  nmap <silent> <buffer> <LocalLeader>ds <Plug>VimspectorStepInto
                  nmap <silent> <buffer> <LocalLeader>df <Plug>VimspectorStepOut
                  nmap <silent> <buffer> <LocalLeader>dc <Plug>VimspectorContinue
                  nmap <silent> <buffer> <LocalLeader>di <Plug>VimspectorBalloonEval
                  xmap <silent> <buffer> <LocalLeader>di <Plug>VimspectorBalloonEval

                  let s:mapped[ string( bufnr() ) ] = { 'modifiable': &modifiable }

                  setlocal nomodifiable

                endfunction

                function! s:OnDebugEnd() abort

                  let original_buf = bufnr()
                  let hidden = &hidden
                  augroup VimspectorSwapExists
                    au!
                    autocmd SwapExists * let v:swapchoice='o'
                  augroup END

                  try
                    set hidden
                    for bufnr in keys( s:mapped )
                      try
                        execute 'buffer' bufnr
                        silent! nunmap <buffer> <LocalLeader>dn
                        silent! nunmap <buffer> <LocalLeader>ds
                        silent! nunmap <buffer> <LocalLeader>df
                        silent! nunmap <buffer> <LocalLeader>dc
                        silent! nunmap <buffer> <LocalLeader>di
                        silent! xunmap <buffer> <LocalLeader>di

                        let &l:modifiable = s:mapped[ bufnr ][ 'modifiable' ]
                      endtry
                    endfor
                  finally
                    execute 'noautocmd buffer' original_buf
                    let &hidden = hidden
                  endtry

                  au! VimspectorSwapExists

                  let s:mapped = {}
                endfunction

                augroup TestCustomMappings
                  au!
                  autocmd User VimspectorJumpedToFrame call s:OnJumpToFrame()
                  autocmd User VimspectorDebugEnded ++nested call s:OnDebugEnd()
                augroup END

                " }}}

                " Custom mappings for special buffers {{{

                let g:vimspector_mappings = {
                      \   'stack_trace': {},
                      \   'variables': {
                      \    'set_value': [ '<Tab>', '<C-CR>', 'C' ],
                      \   }
                      \ }

                " }}}


            ]]
            -- :h vimspector-custom-mappings-while-debugging -- AMEN! they already thought about custom mappings during debugging only!
            -- User autocmds:
            --   VimspectorJumpedToFrame
            --   VimspectorDebugEnded
            --   example: https://github.com/puremourning/vimspector/blob/master/support/custom_ui_vimrc#L13

            vim.keymap.set('n', '<leader>dc', function() require('dap').continue() end) -- <F5>?
            vim.keymap.set('n', '<leader>so', function() require('dap').step_over() end) -- F10?
            vim.keymap.set('n', '<leader>si', function() require('dap').step_into() end) -- F11?
            vim.keymap.set('n', '<leader>su', function() require('dap').step_out() end) -- F12? (s[u] == step up?)
            vim.keymap.set('n', '<leader>sb', function() require('dap').step_back() end)
            -- .pause()
            -- .reverse_continue()
            -- .up()
            -- .down()
            -- .restart_frame()
            -- .run_to_cursor() ***
            -- .set_log_level() ***
            -- .disconnect()
            -- .session/sessions() / .status() / .close()
            -- .launch()
            -- .attach()
            vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
            vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
            vim.keymap.set('n', '<Leader>dl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
            vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.toggle() end) -- toggle instead of open/close
            -- I will likely use legendary for remembering these commands and so its fine for a few to be unrealistic to type out and just for lookup only:
            vim.keymap.set('n', '<Leader>d_r', function()
                require('dap').repl.open()
                require('dap.ext.debugger').restart()
            end)
            vim.keymap.set('n', '<Leader>dt', function()
                require('dap').repl.open()
                require('dap.ext.debugger').terminate()
            end)
            vim.keymap.set('n', '<Leader>d_run_last', function() require('dap').run_last() end) -- a as in again?
            vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function() require('dap.ui.widgets').hover() end)
            vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function() require('dap.ui.widgets').preview() end)
            vim.keymap.set('n', '<Leader>df', function()
                local widgets = require('dap.ui.widgets')
                widgets.centered_float(widgets.frames)
            end)
            vim.keymap.set('n', '<Leader>ds', function()
                local widgets = require('dap.ui.widgets')
                widgets.centered_float(widgets.scopes)
            end)
        end,
    },

}
