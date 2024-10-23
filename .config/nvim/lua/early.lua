---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
-- TODO would be nice to fix these missing globals (and have them resolve to real deal, or worse case explicitly ignore one by one (not all or none))


-- FYI these are mission critical things to have during a failure

--" Uncomment the following to have Vim jump to the last position when reopening a file
vim.cmd([[
    augroup RestoreCursorPosition
        autocmd!
        autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
        " line("'\"") == line # when last closed the buffer/file (per file)
        "    '" is an expression (see :h '")
        " so, as long as '" is within the bounds of the lines in a file, then execute a normal mode command to jump (g) to the '" mark
        "
        "
        " jump to last column too! (TODO do other people not use this? or is it normally considered best to open to the start of the line?)
        autocmd BufReadPost * if col("'\"") > 1 && col("'\"") <= col("$") |  exe "normal! " . col("'\"") . "|" | endif
        "   col("'\"") returns correct last column
        "   10| => jump to line 10 (absolute jump)

        " FYI testing last position:
        "    :echo "line: " . line("'\"") . " - col: " . col("'\"")

    augroup END
]])

-- must come before plugins that use it to define keys
vim.cmd("let g:mapleader = ' '") -- default is '\' which is a bit awkward to reach, gotta take right hand off homerow

-- TODO what do I actaully need here? move any non critical parts elsewhere

-- set this very early, will get an empty failure message from lazy load bootstrap if race conditioon is hit and this comes after some other plugins, also not setting first may change the colorscheme loaded by other plugins
vim.opt.termguicolors = true -- s/b already enabled in most of my environments, maybe warn if not?

vim.o.ignorecase = true      -- ignore case when searching

vim.cmd [[
    " *** fix delete key reporting
    "    it reports 63272 which isn't mapped to <Del>
    "    :echo getchar()  => type the delete key => shows 63272 (whereas vim classic shows <80>kD)
    "       interesting, insert key (above delete) shows <80>kI ... which vim classic also reports, likewise pgup/pgdown show <80>kP/<80>kN in both
    inoremap <Char-63272> <Del>
    cnoremap <Char-63272> <Del>
    " in normal mode, just del current char
    nnoremap <Char-63272> x
    "
    " *** show key reported:
    command! ShowKeyWes echo getchar()
    "
    " *** alt key troubles
    "   fixed w/ iterm setting for now...
    "       Profiles -> Keys -> Left Option Key: Meta (then alt+right works accept-word,  also alt+[/] cycles suggestions, and ctrl+alt+right accepts next line)
    "   fixes several default copilot keybindings
    "   notes:
    "     getchar() w/ alt+right =>
    "         <80><fc>^H<80>kr     " with the iterm setting fix
    "                   <80>kr     " w/o the iterm setting fix
    "         btw, vim classic always has the longer version regardless of iterm2 setting
]]

-- *** left gutter settings
vim.o.signcolumn = 'number' -- yes=always, no=never, auto=only when needed, number=(in # column, if shown)
vim.o.relativenumber = true -- vertical equiv of eyeliner ext (horiz jump marks) - testing if i like this
vim.o.number = false        -- explicitly do not include absolute line #s (for now)
