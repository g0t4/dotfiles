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
                    -- {
                    --     -- FYI showing command history always worries me in video recordings
                    --     --   so leave history off for that reaosn too
                    --     --   that said, I do have per workspace history but still
                    --     --   just complete possible commands
                    --     --   and then the cool thing is, the wilder menu is like adding an arrow to draw attention to the lower left so I don't have to add those in editing!
                    --
                    --     -- FYI this only shows history right now if nothing is typed... useless:
                    --     wilder.check(function(ctx, x) return x == '' end),
                    --     wilder.history(),
                    --     --     -- \       wilder#result({
                    --     --     -- \         'draw': [{_, x -> ' ' . x}],
                    --     --     -- \       }),
                    --     --     -- do I need to show the calendar icon?
                    -- },
                    wilder.cmdline_pipeline({
                        -- sets the language to use, 'vim' and 'python' are supported
                        language = 'python',
                        -- 0 turns off fuzzy matching
                        -- 1 turns on fuzzy matching
                        -- 2 partial fuzzy matching (match does not have to begin with the same first letter)
                        fuzzy = 2, -- !!! what do I want to use?
                        -- TODO go back to fuzzy = 1 if 2 is too busy
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
