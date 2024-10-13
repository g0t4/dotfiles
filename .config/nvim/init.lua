---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global

-- before plugin loader
require("early")

require("bootstrap-lazy")

-- after plugin loader
require("localz.github-links")
require('localz.tabs')
require('localz.misc')

do return end


-- !!! TODO remove packer dirs and cache 

packer.startup(function()


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
    -- mark unique letters to jump to:
    --  use "unblevable/quick-scope" -- quick scope marks jump
    use "jinh0/eyeliner.nvim"   -- lua impl, validated this actually works good and the color is blue OOB which is nicely subtle, super useful on long lines!
    --
    use "karb94/neoscroll.nvim" -- smooth scrolling? ok I like this a bit ... lets see if I keep it (ctrl+U/D,B/F has an animated scroll basically) - not affect hjkl/gg/G
    -- also works with zb/zt/zz which I wasn't aware of but looks useful => zz = center current line! zt/zb = curr line to top or bottom... LOVE IT!
    -- this scratches an itch I had about how it is hard to tell where I am jumping to with page up/down half page up /down etc... this makes it obvious where the movement is headed, long term I might become annoyed by this but its a useful idea... after all we have half page up/down me thinks for a reason that you can see the scroll easier than one full page jump
    require('neoscroll').setup()
    --


    -- PRN indent guides (vertically, like vscode plugin)
    -- use "lukas-reineke/indent-blankline.nvim"

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




    -- highlight just word under cursor:
    use "RRethy/vim-illuminate" -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column
    --    sadly, not the current selection (https://github.com/RRethy/vim-illuminate/issues/196), I should write this plugin
    --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
    --    customizing:
    --      hi def IlluminatedWordText gui=underline
    --      hi def IlluminatedWordRead gui=underline
    --      hi def IlluminatedWordWrite gui=underline
    --

    -- highlight selections like vscode, w/o limits (200 chars in vscode + no new lines)
    use "aaron-p1/match-visual.nvim" -- will help me practice using visual mode too
    -- FYI g,Ctrl-g to show selection length (aside from just highlighting occurrenes of selection)

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
end)
-- TODO: port from vimrc




-- FYI has('mouse') => nvi which is very close to what I had in vim ('a') ... only change if issue arises

--[[
NOTES (vimscript => lua)

vim.cmd({cmd}) to execute a vimscript command

vim.o (== :set)
    https://neovim.io/doc/user/lua.html#vim.o
vim.opt for list/map options (access as lua tables, i.e. append/prepend/remove elements)
    https://neovim.io/doc/user/lua.html#vim.opt
]] --

vim.cmd([[
    " TODO fix when close the original file doesn't show
    command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                  \ | wincmd p | diffthis
]])





-- *** Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file
vim.cmd("nnoremap <c-s> :w<CR>")
vim.cmd("vnoremap <c-s> <Esc><c-s>gv") -- esc=>normal mode => save => reselect visual mode, not working... figure out later
vim.cmd("inoremap <c-s> <c-o><c-s>")




-- map [Shift]+Ctrl+Tab to move forward/backward through files to edit, in addition to Ctrl+o/i
--   that is my goto key combo, perhaps I should learn o/i instead... feel like many apps use -/+ for this, vscode for shizzle
vim.api.nvim_set_keymap('n', '<C-->', '<C-o>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-->', '<C-i>', { noremap = true, silent = true })
--  FYI in iTerm => Profiles -> Keys -> Key Mappings -> removed "send 0x1f" on "ctrl+-" ... if that breaks something, well you have this note :)


-- *** ASK OPENAI wrapper
vim.cmd([[
    " nvim observation: nested languages in lua are highlighted nicely!
    "   lua observation: multiline strings rock for embedding other languages

    " TODO review prompt and see if I should specify this is neovim vs classic... in fact I should update this wrapper to differentiate and pass that

    function! TrimNullCharacters(input)
        " Replace null characters (\x00) with an empty string
        " was getting ^@ at end of command output w/ system call (below)
        return substitute(a:input, '\%x00', '', 'g')
    endfunction

    function! AskOpenAI()

        let l:cmdline = getcmdline()

        " todo this prompt here should be moved into vim.py script and combined with other system message instructs? specifically the don't include leading :? or should I allow leading: b/c it still works to have it
        let l:STDIN_text = ' env: nvim (neovim) command mode (return a valid command w/o the leading : ) \n question: ' . l:cmdline

        " PRN use env var for DOTFILES_DIR, fish shell has WES_DOTFILES variable that can be used too
        let l:DOTFILES_DIR = '~/repos/wes-config/wes-bootstrap/subs/dotfiles'
        let l:py = l:DOTFILES_DIR . '/.venv/bin/python3'
        let l:vim_py = l:DOTFILES_DIR . '/zsh/universals/3-last/ask-openai/vim.py'
        let l:command_ask = l:py . ' ' . l:vim_py

        let l:result = system(l:command_ask, l:STDIN_text)

        return TrimNullCharacters(l:result)

    endfunction

    " Map a key combination to the custom command in command-line mode
    cmap <C-b> <C-\>eAskOpenAI()<CR>

]])


-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    local myTable = vim.treesitter.get_captures_at_cursor()
    for key, value in pairs(myTable) do
        print(key, value)
    end
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")
local ts = vim.treesitter

local ts_utils = require 'nvim-treesitter.ts_utils'

-- TODO format vimscript (nested in lua)
-- ***! foo

-- TODO! test lua comment
-- TODO test too
-- TODO! treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. so how does that relate to my syntax/highlight groups? how do I see that?
vim.cmd [[

    " FYI if I can also remove @comments capture linkage https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/lua/highlights.scm#L229-L230
    " TODO add custom capture that targets subset of comments insted of using regex, so I can target both syntax and/or treesitter highlight systems

    " !!! TMP fix sets no bg color on comments ... which means here then in nested multiline vimscript lua's orange color applies which is fine ish
    " FYI! NBD that color is orange here... I can fix the overlapping priority later... heck even the lua issue isn't a deal breaker as all other files seem to not have issue (yet, maybe treesitter on them will cause issues)
    " * override Comment color => changes the fg!
    "hi Comment ctermfg=65 guifg='#6a9955'   "original => Last set from ~/.local/share/nvim/site/pack/packer/start/vim-code-dark/colors/codedark.vim
    " hi Comment ctermfg=65 guibg='#6a9955' guifg='#0101ff' "!!! bgcolor takes precedence too, so its a precedence issue IIGC
    " hi Comment ctermfg=65 guifg='#0101ff' gui=NONE " NONE doesn't take precedence, is that even valid though?
    hi clear Comment " clear it fixes the fg color ... b/c then yeah a comment doesn't have a fg color... ok... but can I add back color as a lower precedence rule?
    " OMG OMG  if I break this style with invalid guifg!! my styles work in lua!!!! **tears** (all damn day beating around this bush)


    " explore capture => highlighting
    " captures are linked to existing highlight groups (IIUC for the most part), i.e.:
    ":hi TestNewHigh gui=bold guibg=red guifg=blue " create new highlight rule
    ":hi link @comment TestNewHigh  " link capture to it
    " FYI here is logic to add higlighting to a node: (is this used by extensions?)  https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua#L268

]]

-- FYI! foo
-- !!! FOO
-- alternative way to replace higlight group:
-- -- vim.api.nvim_set_hl(0, "Comment", {})
-- -- vim.api.nvim_set_hl(0, "Comment", { fg = "#6a9955" })
-- vim.api.nvim_set_hl(0, "@comment", {})

function print_ts_cursor_details()
    -- FYI, use :InspectTree => :lua vim.treesitter.inspect_tree() => interactive select/inspect left/right split
    local node_at_cursor = ts_utils.get_node_at_cursor()
    if node_at_cursor then
        print("Node type: ", node_at_cursor:type())
        print("node text: ", vim.treesitter.get_node_text(node_at_cursor, 0)) -- shows the original source! FYI 0 = buffer with text, node lookup into that buffer IIUC
    else
        print("No node found")
    end

    -- API: https://neovim.io/doc/user/api.html
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

    -- FYI drop local to snoop on variables, i.e. parser:
    local parser = ts.get_parser(0)
    local lang_tree = parser:language_for_range({ cursor_row - 1, cursor_col, cursor_row - 1, cursor_col })
    if lang_tree then
        local lang_name = lang_tree:lang()
        print("language: ", lang_name)
    else
        print("language: unknown")
    end


    print("captures:")
    print_captures_at_cursor()

    -- TODO can I get highligther info from treesitter? too? think what I did below but for treesitter
    -- local id = parser:syntax_tree():get_property("highlighter"):query("highlighter", cursor_row, cursor_col)
    -- print(id)

    print("syntax highlighting (not treesitter highlighting):")
    print("name gui:'", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, false), "name", "gui"),
        "' - cterm:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, false), "name", "cterm"))

    print("highlight:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "highlight", ""))
    print("fg:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "fg", "gui"),
        "bg:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bg", "gui"))
    -- print("fg#:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "fg#", "gui"),
    --     "bg#:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bg#", "gui"))
    print("bold:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bold", ""))
    print("italic:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "italic", ""))
    print("underline:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "underline", ""))
    print("undercurl:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "undercurl", ""))

    -- TODO!  test lua commment

    -- IIAC => if have multi syntax/highlight regex hits... then I can show them all here... but won't show any treesitter highlights
    local stack = vim.fn.synstack(cursor_row, cursor_col)
    -- print("length:", #stack)
    -- -- loop:
    for key, value in pairs(stack) do
        print("stack:", key, value, vim.fn.synIDattr(value, "name", "gui"))
    end
end

vim.cmd("nnoremap <leader>pd :lua print_ts_cursor_details()<CR>")

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        vim.cmd("source ~/.config/nvim/highlights.vim")
    end
})






-- vim.api.nvim_set_hl(0, "vimAutoCmd",{ fg = "red", bg = "red"})

-- TODO
-- load wilder.vim:
-- vim.cmd('source /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/nvim/todo_vimrc.vim')

-- HIGHLIGHT 3 (maybe) => ultimately I need to understand what all is fighting over highlights/syntax/etc (treesitter, vim regex syntax, LSP too?, syntect (sublime text)..)
--     autocmd filetype    -- super helpful way to see what is applied in what order (where I found the autocmds were registered too early... so maybe put back earlier registration and see if I can find the things in between that are overriding higlights)
--         IN FACT => do binary search on registration order in the plugin chain... see if I can narrow the extension causing issues, IIAC
-- " !!! try AFTER plugin config:
--
-- use {
--   'plugin-to-load-second',
--   after = 'plugin-to-load-first',
--   config = function()
--     -- Your Vimscript or Lua code that depends on `plugin-to-load-first`
--     vim.cmd('echo "Plugin loaded after plugin-to-load-first"')
--   end
-- }
-- OBSERVATIONS:
--   both bg and gui=bold are applied correctly to lua files... just the fg color?!
--   nvim -u NONE ~/.config/nvim/init.lua
--     run w/ no plugins => then
--       :source  ~/.config/nvim/immediate.highlights.vim
--            WORKS! applies my style to FYI below

--
-- HIGHLIGHT ISSUE 2 => lua seems to have smth else styling it and that is overrding fg colors... I dont think its treesitter b/c I configured it to disable it and this still persisted..
--
--
-- HIGHLIGHT ISSUE 1 => most files the style didn't apply (until I discovered you reload the file and that registers the autocmd FileType entries again and that must be overrdiing whatever is blocking the first registration which was before many plugin highlights...)
-- ensure highlight style applied late in load process (before buffer ready but just after file read)...  b/c right now if these are registered earlier (ie before packer plugins...) then the style wont take effect until next file opened
--
--

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

-- -- *** folding config
-- --   (move to treesitter config?)
-- --   https://neovim.io/doc/user/fold.html
-- --   TODO setup per filetype? limit to lua for now?
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
-- -- vim.o.foldenable = false -- no autofolding, just manual after open file
-- -- TODO setup saving folds, sessionoptions has folds but... those might be diff folds? (b/c I tried foldopen command and then zo/zc no longer worked until restart vim, is there a sep fold system?)
--
--
