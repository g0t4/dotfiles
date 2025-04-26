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
            ]]
            -- :h vimspector-custom-mappings-while-debugging -- AMEN! they already thought about custom mappings during debugging only!
            -- User autocmds:
            --   VimspectorJumpedToFrame
            --   VimspectorDebugEnded
            --   example: https://github.com/puremourning/vimspector/blob/master/support/custom_ui_vimrc#L13
        end,
    },

}
