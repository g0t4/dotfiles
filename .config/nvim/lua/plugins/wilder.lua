return {

    {
        -- !!! cons/issues to fix:
        -- - it's duplicating characters during completion:
        --    i.e. vim.a<TAB><ACCEPT> => vim.aapi
        -- - tab completion fuzzy match is not working for sub completions unless first char is same as completion
        --    so:   vim.api.get<TAB> (no matches), whereas vim.api.nvim_get<TAB> has matches!
        --              is this an option somewhere? I set fuzzy = 2 but that doesn't seem to work for these .sub completions?

        -- *** possible things to try:
        -- - should it select first item automatically, w/o putting it into buffer? and then accept populates it? https://github.com/gelguy/wilder.nvim/issues/67
        --     try:   call wilder#set_option('noselect', 0)
        --     like nvim-cmp does, so you can just arrow up/down to select items in popup menu right away? or would that break cycling history?
        -- - I'd like to see how I feel about seleting a path based on fuzzy match entire path not just one dir at a time

        -- FYI wildmenu is pretty good too, can use fuzzy in it too:
        -- set wildoptions=pum,fuzzy,tagfile -- pum,tagfile by default
        -- doesn't show until hit tab
        -- SO I can always go back to this if wilder isn't adding anything material or if I don't like it showing right away

        enabled = false, -- PRN if use nvim-cmp (cmdline/search completions) then disable wilder here
        "gelguy/wilder.nvim",
        -- TODO lazy load https://github.com/gelguy/wilder.nvim?tab=readme-ov-file#faster-startup-time
        dependencies = {
            'nvim-tree/nvim-web-devicons'
        },
        config = function()
            require("wilder").setup {
                modes = {
                    "/", -- absolutely love this for searching, so darn awesome
                    "?",
                    ":", -- cmd completion that is fuzzy!
                },
                -- enable_cmdline_enter = false, -- only show on tab... I like to see it right away!... maybe if it could show after first chars typed and not smth like :w or :q?... I love having it show up on help lookups especially, wouldn't wanna have to tab on every `:h *`
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

            -- use popup menu for everything (see _mux to change based on menu type)
            -- TODO try better highlighter: https://github.com/gelguy/wilder.nvim?tab=readme-ov-file#better-highlighting (figure out what doesn't work well first)
            wilder.set_option('renderer', wilder.popupmenu_renderer({
                -- highlighter applies highlighting to the candidates
                highlighter = wilder.basic_highlighter(),
                highlights = {
                    default = 'MyWilderPopupmenu',
                    selected = 'MyWilderPopupmenuSelected',
                    accent = 'MyWilderPopupmenuAccent',
                    selected_accent = 'MyWilderPopupmenuSelectedAccent',
                },
                left = {
                    ' ',
                    wilder.popupmenu_devicons(),
                },
                right = {
                    -- PRN wire up page up/down to scroll?
                    ' ', wilder.popupmenu_scrollbar()
                },
            }))

            vim.cmd [[
                highlight MyWilderPopupmenu guifg=#90ee90
                highlight MyWilderPopupmenuSelected guibg=#ee9090 guifg=#282828
                highlight MyWilderPopupmenuAccent gui=bold guibg=#d0ffd0 guifg=#282828
                highlight MyWilderPopupmenuSelectedAccent gui=bold guibg=#ffd0d0 guifg=#282828
            ]]
        end,
    }

}
