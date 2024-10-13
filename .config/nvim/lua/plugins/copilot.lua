return {
    {
        'github/copilot.vim',
        event = { "InsertEnter", "BufReadPost" }, -- Load when entering insert mode or opening a file
        config = function()
            vim.cmd([[
                "" copilot consider map to ctrl+enter instead of tab so IIUC other completions still work, O
                "imap <silent><script><expr> <C-CR> copilot#Accept("\\<CR>")
                "let g:copilot_no_tab_map = 1
                "" ok I kinda like ctrl+enter for copilot suggestions (vs enter for completions in general (coc)) but for now I will put tab back and see if I have any issues with it and swap this back in if so

                function! ToggleCopilot()
                    " FYI https://github.com/github/copilot.vim/blob/release/autoload/copilot.vim

                    " FYI only global toggle, not toggling buffer local

                    " PRN save across sessions? maybe modify a file that is read on startup (not this file, I want it out of vimrc)

                    if copilot#Enabled()
                        Copilot disable
                    else
                        Copilot enable
                    endif

                    " echo "copilot is: " . (g:copilot_enabled ? "on" : "off")
                    Copilot status " visual confirmation - precise about global vs buffer local too
                endfunction

                :inoremap <F12> <Esc>:call ToggleCopilot()<CR>a
                " :inoremap <F12> <C-o>:call ToggleCopilot()<CR> " on empty, indented line, causes cursor to revert to start of line afterwards
                :nnoremap <F12> :call ToggleCopilot()<CR>

            ]])
        end,
    }

}
