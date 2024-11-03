return {



    {
        "gelguy/wilder.nvim",
        config = function()
            -- TODO port config from vimrc
            require("wilder").setup {
                modes = {
                    "/",
                    "?",
                    ":",
                    ";",
                },
            }

            vim.cmd [[

" FYI quit/reopen vim when changing highlight parameters (i.e. ctermfg)
highlight MyWilderPopupmenu ctermfg=121 " seagreen color, based on MoreMsg highlight group builtin
highlight MyWilderPopupmenuSelected ctermbg=9 " red bg, based on DiffText builtin (FYI to test this search files and hit Tab to step through search results popup menu)
highlight MyWilderPopupmenuAccent cterm=bold ctermfg=0 " test by searching commands (prefix matches is accent color)
highlight MyWilderPopupmenuSelectedAccent cterm=bold ctermfg=0 ctermbg=9" test by search commmands (i.e. :w and tab to select and step through)
" :h popupmenu_renderer  => (highlights groups) =>
"   - default (default=PMenu),
"   - selected (default=PmenuSel)
"   - error (default=ErrorMsg)
"   - accent (default=default + underline + bold)
"   - selected_accent (default=selected + underline + bold)
"   - empty_message (default=WarningMsg)
"
" use popup menu for everything (see _mux below for diff menu based on type)
call wilder#set_option('renderer', wilder#popupmenu_renderer({
      \ 'highlighter': wilder#basic_highlighter(),
      \ 'highlights': {
      \   'default': 'MyWilderPopupmenu',
      \   'selected': 'MyWilderPopupmenuSelected',
      \   'accent': 'MyWilderPopupmenuAccent',
      \   'selected_accent': 'MyWilderPopupmenuSelectedAccent',
      \ },
      \ 'left': [
      \   ' ', wilder#popupmenu_devicons(),
      \ ],
      \ 'right': [
      \   ' ', wilder#popupmenu_scrollbar(),
      \ ],
      \ }))

            ]]
        end,

    }

}
