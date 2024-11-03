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
                },
            }

            vim.cmd [[

highlight MyWilderPopupmenu guifg=#90ee90
highlight MyWilderPopupmenuSelected guibg=#9090ee guifg=#282828
highlight MyWilderPopupmenuAccent gui=bold
highlight MyWilderPopupmenuSelectedAccent gui=bold guibg=#9090ee guifg=#282828

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
