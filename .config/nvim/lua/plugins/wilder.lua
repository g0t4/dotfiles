return {



    {
        "gelguy/wilder.nvim",
        config = function()
            require("wilder").setup {
                modes = {
                    "/",
                    "?",
                    ":",
                },
            }

            local wilder = require('wilder')
            wilder.set_option('pipeline', {
                wilder.branch(

                -- FYI showing command history always worries me in video recordings
                --   so leave history off for that reaosn too
                --   that said, I do have per workspace history but still
                --   just complete possible commands
                --   and then the cool thing is, the wilder menu is like adding an arrow to draw attention to the lower left so I don't have to add those in editing!
                -- PRN add back check to only show history when nothing typed in... I might wanna have history if I can filter it (i.e. fish shell, not fuzzy but on subset and not start of string)
                -- wilder.history(), -- if I am only gonna show this on empty... I can just use the up arrow already b/c that is all I can do with wilder in this case anyways...

                    wilder.cmdline_pipeline({
                        -- sets the language to use, 'vim' and 'python' are supported
                        language = 'python',
                        -- 0 turns off fuzzy matching
                        -- 1 turns on fuzzy matching
                        -- 2 partial fuzzy matching (match does not have to begin with the same first letter)
                        fuzzy = 2, -- TODO go back to fuzzy = 1 if 2 is too busy
                        -- awesome to use this for help files... :h history
                    }),
                    wilder.python_search_pipeline({
                        -- can be set to wilder#python_fuzzy_delimiter_pattern() for stricter fuzzy matching
                        pattern = wilder.python_fuzzy_pattern(),
                        -- omit to get results in the order they appear in the buffer
                        sorter = wilder.python_difflib_sorter(),
                        -- can be set to 're2' for performance, requires pyre2 to be installed
                        -- see :h wilder#python_search() for more details
                        engine = 're',
                    })
                ),
            })

            vim.cmd [[

highlight MyWilderPopupmenu guifg=#90ee90
highlight MyWilderPopupmenuSelected guibg=#ee9090 guifg=#282828
highlight MyWilderPopupmenuAccent gui=bold guibg=#d0ffd0 guifg=#282828
highlight MyWilderPopupmenuSelectedAccent gui=bold guibg=#ffd0d0 guifg=#282828

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
