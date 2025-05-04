-- before plugin loader
require("early")

require("bootstrap-lazy")

-- TODO! move any non-plugin config into the virtual plugin in g0t4.lua plugin spec set, esp if it needs to run after a plugin
-- TODO! goal is to push all config into expressing its dependencies and loading as a plugin... to avoid race conditions hell
-- after plugin loader (but not guaranteed to be after specific plugins)
require('werkspace')

vim.cmd [[
    " TODO where should I consolidate these?
    " fix some theme issues
    "
    " without this, the cursor line in NvimTree is blindingly bright... and for some reason once it is used it sets CursorLine in subsequently opened files... very strange
    "   this forces NvimTreeCursorLine to be the same as CursorLine
    " NvimTreeCursorLine xxx guibg=#5c6370
    " CursorLine     xxx guibg=#2d313b
    highlight! link NvimTreeCursorLine CursorLine
]]

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

-- TODO!!! FORMATTER focused extension:
-- use 'stevearc/conform.nvim' -- can replace LSP formatters that are problematic, per file type... DEFINITELY LOOK INTO THIS

-- *** bar
-- * foo
-- ***! foo
-- FOO bar
-- TODO COMMENT alternatives:
-- use 'numToStr/Comment.nvim' -- more features like gc$ (not entire line)
-- use 'JoosepAlviste/nvim-ts-context-commentstring' -- context aware commentstring, IIUC for issues with embedded languages and commenting... FYI embedded vimscript in lua, gcc works fine

-- ? foo
-- ?? foo
-- ??? foo
-- ! foo
-- !!! foo
-- TODO git related
-- use "tpope/vim-fugitive" =>
-- use "lewis6991/gitsigns.nvim" -- git code lens essentially, never been a huge fan of that in vscode

-- PRN! bufferline? tab strip with buffers (in addition to tabs)... interesting, gotta think if I want this, I kinda like it right now because I can see what files I have open... I would also wanna know key combos (or set those up for switching buffers, vs tabs)... I need to learn better what the intent is w/ a buffer vs tab, the latter you can :q to quit but the former is like multiple per tab (one :q closes all buffers)... also have :bdelete (close), etc
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
