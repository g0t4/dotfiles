-- FYI these are mission critical things to have during a failure





vim.cmd [[
    augroup RestoreCursorPosition
        autocmd!

        " FYI g'" restores to first non-blank char of line (TLDR doesn't restore column)
        "     g`" restores to exact position (line and column)
        autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif
        " line("'\"") == line # when last closed the buffer/file (per file)
        "    '" is an expression (see :h '")
        " so, as long as '" is within the bounds of the lines in a file, then execute a normal mode command to jump (g) to the '" mark

        "" FYI testing last position:
        "autocmd BufReadPost * echom "line " . line("'\"") . " col " . col("'\"") . " file " . expand("%:p")

    augroup END
]]






-- must come before plugins that use it to define keys
vim.cmd("let g:mapleader = ' '") -- default is '\' which is a bit awkward to reach, gotta take right hand off homerow

-- set this very early, will get an empty failure message from lazy load bootstrap if race conditioon is hit and this comes after some other plugins, also not setting first may change the colorscheme loaded by other plugins
vim.opt.termguicolors = true -- s/b already enabled in most of my environments, maybe warn if not?

vim.o.ignorecase = true      -- ignore case when searching

-- shortmess in nvim defaults to => ltToOCF
-- set shortmess+=A " don't give ATTENTION messages if already open in another instance (swap file detected)
-- set shortmess+=I " don't give intro message (if no file passed in)
-- set shortmess-=S " remove S so see search count and W for wrapped indicator
vim.o.shortmess = vim.o.shortmess .. "A" .. "I"

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
vim.o.number = true         -- explicitly do not include absolute line #s (for now)
-- relative + number == absolute instead of 0 for current cursor line (rest are relative)

-- *** help gutter settings (global options don't apply here)
vim.api.nvim_create_augroup("HelpNumbers", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = "HelpNumbers",
    pattern = "help",
    command = "setlocal relativenumber number",
})
