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
            -- TODO keys
            --   review: https://puremourning.github.io/vimspector-web/#debugging
            --   TODO finish reviewing checklist in vimspector-checklist.vim (next to this file)
            --   let g:vimspector_enable_mappings = 'HUMAN' " https://github.com/puremourning/vimspector?tab=readme-ov-file#human-mode

            vim.cmd [[

                "
                " * always map:
                "  FYI yes I am probably abusing <LocalLeader> to map it all the time... for now I see it as "SecondaryLeader" until I incorporate the idea of LocalLeader better into my keymaps
                nmap <F5> <Cmd>call vimspector#Launch()<CR>
                " FYI :VimspectorLaunch cmd does not respect "default" config property, it must be passing args to Launch?
                " FYI consider <LocalLeader>dt if you start using LocalLeader for other purposes
                "   for now, given this is all I use LocalLeader for... I can reserve top level keymaps to simplify the "keymap namespace"
                nmap <silent> <LocalLeader>t <Cmd>call vimspector#Reset()<CR>
                " allow reset (close) vimspector anytime (buffer LocalLeader maps below are unmapped on stop, when debugger stops, i.e. run past end of program b/c had no breakpoints)
                " FYI consider <LocalLeader>db
                nmap <silent> <LocalLeader>b  <Cmd>call vimspector#ToggleBreakpoint()<CR>
                nmap <silent> <LocalLeader>bn <Cmd>call vimspector#JumpToNextBreakpoint()<CR>
                nmap <silent> <LocalLeader>bp <Cmd>call vimspector#JumpToPreviousBreakpoint()<CR>
                " vimspector#ToggleConditionalBreakpoint() ?
                " FYI advanced asks for values for conditional expr, hit count, log point expr using cmdline, nice Ux
                nmap <silent> <LocalLeader>ba <Cmd>call vimspector#ToggleAdvancedBreakpoint()<CR>
                nmap <silent> <LocalLeader>bl <Cmd>call vimspector#ListBreakpoints()<CR>
                nmap <silent> <LocalLeader>bclear <Cmd>call vimspector#ClearBreakpoints()<CR>
                " TODO how about a keymap to send word under cursor / selection to the console to eval it?
                "    console doesn't truncate multi-line strings like inspect is doing
                "    call vimspector#Evaluate[Console]("foo")

                " TODO how hard would it be to persist breakpoints across restarts? Would I want this?
                "   not sure how often I would want this?

                " Custom mappings while debugging {{{
                " :h vimspector-custom-mappings-while-debugging -- AMEN! they already thought about custom mappings during debugging only!
                " User autocmds:
                "   VimspectorJumpedToFrame
                "   VimspectorDebugEnded
                "   example: https://github.com/puremourning/vimspector/blob/master/support/custom_ui_vimrc#L13

                let s:mapped = {}

                function! s:OnJumpToFrame() abort
                  if has_key( s:mapped, string( bufnr() ) )
                    return
                  endif

                  " FYI these are reviewed:
                  " FYI LocalLeader allows overriding leader keys for current buffer (that way global <leader> keymaps aren't affected)
                  " sn = next (better ideas?).. do I want over or out to have so?
                  "   OR?  su (up/out), so (over), si (in/down)?
                  nmap <silent> <buffer> <LocalLeader>sn <Plug>VimspectorStepOver
                  nmap <silent> <buffer> <LocalLeader>si <Plug>VimspectorStepInto
                  nmap <silent> <buffer> <LocalLeader>so <Plug>VimspectorStepOut

                  " FYI rtc just first idea, if used alot I may hate it
                  nmap <silent> <buffer> <LocalLeader>rtc <Plug>VimspectorRunToCursor

                  nmap <silent> <buffer> <LocalLeader>dc <Plug>VimspectorContinue
                  " instead of mouse hover, use this to show hover
                  " TODO dh instead of di? (h for hover, vs i for inspect)
                  nmap <silent> <buffer> <LocalLeader>i <Plug>VimspectorBalloonEval
                  xmap <silent> <buffer> <LocalLeader>i <Plug>VimspectorBalloonEval
                  nmap <silent> <buffer> <LocalLeader>dre <Plug>VimspectorRestart
                  nmap <silent> <buffer> <LocalLeader>dstop <Plug>VimspectorStop
                  " TODO can I override my F9 keymap for vimspector tab to call reset (which closes all windows, OR close all its windows, not just current window)?



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
                        " TODO port to lua and use a keymaps table array to unregister so I don't duplicate keymap lhs here:
                        silent! nunmap <buffer> <LocalLeader>sn
                        silent! nunmap <buffer> <LocalLeader>si
                        silent! nunmap <buffer> <LocalLeader>so

                        silent! nunmap <buffer> <LocalLeader>rtc

                        silent! nunmap <buffer> <LocalLeader>dc
                        silent! nunmap <buffer> <LocalLeader>i
                        silent! xunmap <buffer> <LocalLeader>i
                        silent! xunmap <buffer> <LocalLeader>dre
                        silent! xunmap <buffer> <LocalLeader>dstop

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

            -- FYI these are from nvim dap plugin... use as a checklist for reviewing and changing the above conditional vimspector keymaps
            -- vim.keymap.set('n', '<leader>sb', function() require('dap').step_back() end)
            --
            -- vim.keymap.set('n', '<Leader>dl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
            -- vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.toggle() end) -- toggle instead of open/close
            -- -- I will likely use legendary for remembering these commands and so its fine for a few to be unrealistic to type out and just for lookup only:
            -- vim.keymap.set('n', '<Leader>d_run_last', function() require('dap').run_last() end) -- a as in again?
            -- vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function() require('dap.ui.widgets').preview() end)
            -- vim.keymap.set('n', '<Leader>df', function()
            --     local widgets = require('dap.ui.widgets')
            --     widgets.centered_float(widgets.frames)
            -- end)
            -- vim.keymap.set('n', '<Leader>ds', function()
            --     local widgets = require('dap.ui.widgets')
            --     widgets.centered_float(widgets.scopes)
            -- end)
        end,
    },

}
