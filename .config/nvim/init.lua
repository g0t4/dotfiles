-- before plugin loader
require("early")

require("bootstrap-lazy")
require("werkspace") -- TODO do I need this earlier?
-- after plugin loader
require("localz.github-links")
require('localz.tabs')
require('localz.misc')
require('localz.ask-openai')
require('localz.clippy')
require('localz.my-comment-highlights')
require('localz.filetypemods')

-- workspace constraints:
--  (thoughts about what will eventually formulate my session restore plugins/scripts)
--
--  doing:
--  - autcmd to restore buffer position when file opened (stored in shada?)
--    - also jumps, cmd history (IIUC these are all in shada)
--
--  define workspace:
--  - boundary around which I want to track state and restore it
--  - == single repo root dir (95%+ of the time)
--  - == directory (99% of the time)
--    - == org dir (above org's cloned repos)
--
--  per workspace state:
--   - jump list per workspace (like vscode)
--      - instead of global jump list?
--   - command history tied to workspace?
--   - what else in shada or otherwise?
--
--  NOTES:
--  - telescope find_files has CWD (i.e. open repo while PWD is in a subdir and it only shows a subset of files in that subdir, not terrible actually, I like that when I wanna focus on a subset of a repo but keep things like jumps, cmd history, etc)
--

    -- TODO FORMATTER focused extension:
    -- use 'stevearc/conform.nvim' -- can replace LSP formatters that are problematic, per file type... DEFINITELY LOOK INTO THIS

    -- TODO COMMENT alternatives:
    -- use 'numToStr/Comment.nvim' -- more features like gc$ (not entire line)
    -- use 'JoosepAlviste/nvim-ts-context-commentstring' -- context aware commentstring, IIUC for issues with embedded languages and commenting... FYI embedded vimscript in lua, gcc works fine

    -- TODO git related
    -- use "tpope/vim-fugitive" =>
    -- use "lewis6991/gitsigns.nvim" -- git code lens essentially, never been a huge fan of that in vscode

    -- PRN bufferline? tab strip with buffers (in addition to tabs)... interesting, gotta think if I want this, I kinda like it right now because I can see what files I have open... I would also wanna know key combos (or set those up for switching buffers, vs tabs)... I need to learn better what the intent is w/ a buffer vs tab, the latter you can :q to quit but the former is like multiple per tab (one :q closes all buffers)... also have :bdelete (close), etc
    -- keep for now as a reminder I wanna figure out how to work with a multi open doc system in vim now, later (like vscode), I suspect I will get rid of the tab strip? or just go to showing current file name in title of entire app would be fine too
    -- use {'akinsho/bufferline.nvim', tag = "*", requires = 'nvim-tree/nvim-web-devicons'}
    -- require("bufferline").setup({})

    -- PRN cursor line (highlight selected line AND also does illuminate task of showing current word (under cursor) occurrences underlined)
    -- yamatsum/nvim-cursorline

    -- TODO review list of extensions here:
    -- https://nvimluau.dev/akinsho-bufferline-nvim (TONS of extensions and alternatives including statusline, bufferline, etc
    --
    -- https://nvimluau.dev/meznaric-conmenu  # context menu for nvim (ie format,  code actions, would this be useful?)
    -- https://nvimluau.dev/hood-popui-nvim  # boxes around UI elemennts like hover boxes?
    --

    -- PRN customize statusline plugin (though I don't care for a bunch of crap I don't need to see, i.e. git branch shouldn't waste screen space)
    -- use "nvim-lualine/lualine.nvim" -- maybe useful for small customizations, i.e. I wanna show selected char count in visual selection mode

    -- PRN catppuccin/nvim # UI themes, might have smth good or ideas for my own theme mods

    -- PRN mrjones2014/smart-splits.nvim => better way to manage splits with tmux and nvim? not sure I need this but maybe ideas for doing similar in iterm2?

    -- HRM... tris203/precognition.nvim => shows keys to use to jump to spots... might be a good way for beginners to learn about what keys to use in a situation?


    -- gelguy/wilder.nvim  # compare to builtin picker and fuzzy finder instead?
    --    port config from vimrc if I use this
    --    can I setup wilder to not show unless I hit tab? I like how that works in nvim's menu picker OOB
    --
    -- Plugin 'ryanoasis/vim-devicons'
    --
    -- Plugin 'tpope/vim-commentary'  # switch to this if I don't like bundled comment in neovim
    --
    -- editorconfig? (bundled, right?)

    -- TSModuleInfo shows nothing setup?! including nothing for lua?
    -- :scriptnames # shows loaded files BTW => useful to see if syntax/lua.vim loaded (how I found it uses ftplugin/lua.lua to specify tree sitter)
    --
    -- :TSInstall lua
    -- :TSBufEnable highlight # now TSModuleInfo shows lua!... TODO what is gonna be different? I need to research what to expect and see if I can even identify differences
    --
    -- :TSInstallInfo



    --  nacro90/numb.nvim -- peek line #s while go to (:123) and hide again after, also other peeks (cursorline)
    -- TODO: foo the bar
    --
    -- TODO other (TODO set so not need trailing colon?)
    --
    -- FIXME fo asdf foajho
    -- NOTE foo
    -- CUSTOM foo the bar
    -- use {
    --     "folke/todo-comments.nvim",
    --     requires = "nvim-lua/plenary.nvim",
    --     config = function()
    --         require("todo-comments").setup {
    --             highlight = {
    --                 -- before = "bg",
    --                 keyword = "bg",
    --                 after = "bg",
    --                 pattern = [[.*<(KEYWORDS)\s*]],
    --             },
    --             signs = false, -- show icons in the gutter
    --             -- You can add custom keywords and styles here
    --             keywords = {
    --                 -- TODO = { icon = " ", color = "info" },
    --                 -- FIXME = { icon = " ", color = "error" },
    --                 -- NOTE = { icon = " ", color = "hint" },
    --                 -- CUSTOM = { icon = " ", color = "warning" }, -- Custom keyword example
    --             },
    --         }
    --     end
    -- }



vim.cmd [[
    "" todo setup auto session extension instead? AND an extension for tracking session history (*like vscode recent folders feature*)...
    "" hopefully something has a telescope compat picker to select the session to restore?
    "
    "" Automatically save session when leaving Vim
    "autocmd VimLeavePre * if (isdirectory(".git") || filereadable(".git")) | mksession! session.vim | endif
    "
    "" Automatically load session when opening Vim in a Git repository
    "autocmd VimEnter * if filereadable("session.vim") | source session.vim | endif
    "
    "" highlighting doesn't work on first load of session (until e! or run filetype detect)
    "autocmd SessionLoadPost * silent! filetype detect
]]

