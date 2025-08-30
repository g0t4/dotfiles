-- FYI these are mission critical things to have during a failure

-- timeoutlen = 1000 by default, always felt SLUGGISH... why did I not try to change this before!
--   this affects overlapping keymaps:
--   i.e. <S-k> and <S-k><S-k>
--   it waits 1 second after K alone b/c it needs to see if its gonna be KK
--   but for KK it can immediately activate b/c there's no ambiguity
vim.o.timeoutlen = 300
--  FYI some things will still feel slow if there's a lag to load them but the shortcut is firing after 300ms of no more keystrokes.
--    test with <leader>l  # I have others like <leader>ls so it has to wait on just l
--    that said first load feels slow (either telescope or coc initial load hit)
--
-- consider dynamic setting based on context?
-- vim.api.nvim_create_autocmd("InsertEnter", {
--     callback = function()
--         vim.o.timeoutlen = 100
--     end,
-- })
-- vim.api.nvim_create_autocmd("InsertLeave", {
--     callback = function()
--         vim.o.timeoutlen = 300
--     end,
-- })



vim.cmd [[

    " FYI must have either wait:N or hit-enter, and history:N is always required
    " wait:N means show hit-enter for N seconds and then advance
    " hit-enter means stop on wrapped lines
    " THANK GOD this was added in v0.11..
    "
    " ok so I really only want this for startup to avoid showing the goddamn filename and blocking on it
    " ok wait:0 is not at all a fix for the issue.. b/c then all messages flash up (at least don't show them if its 0)... but there are plenty of messages I WANT to see and leave open...
    "   TODO just override printing messages and make my own implementation? based on message contents
    "     TODO better yet, route all messages to a diff interface that I make? I hate the little messages w/e it is... it's a terrible interface (not at all vim like)
    " EVEN BETTER... can I just get this to not block startup?
    "   I have never had a problem with hit-enter normally, just don't like that it blocks startup
    "   there s/b a way to say stop/block on errors... NOT block if line is longer than width of screen... WTF
    "   OMFG ... this applies to :messages too... WTGDF people?!??!!?!
    "         I can't use this if :messages is broken
    " wait:1000 is buggy too... first few times I run :messages it flickers and closes instantly... then later it respects my wait:1000
    "    also, it seems wait:0 is clearing message history? or?
    "set messagesopt+=wait:0
    "set messagesopt-=hit-enter
    " * discussion around messagesopt (still open) https://github.com/neovim/neovim/issues/1029

    " use venv specific to dotfiles repo for nvim purposes, double check with:
    "   :checkhealth provider.python
    let g:python3_host_prog = $HOME . "/repos/github/g0t4/dotfiles/.venv/bin/python3"

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

vim.o.ignorecase = true -- ignore case when searching (i.e. lowercase/mixing case... all are ignored)
vim.o.smartcase = true -- then, smart case means if you mix case then it will trigger noignorecase like behavior
-- helpers for finding naming styles

-- camelCase
-- PascalCase
-- snake_case

local upper = "\\u"
local lower = "\\l"
local one_or_more = "\\+"
local word = "\\w"
local digit_or_lower = "\\(\\l\\|\\d\\)"
local lower_or_digit = digit_or_lower
local word_start = '\\<'
local word_end = '\\>'

vim.api.nvim_create_user_command('CamelCase', function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(
            '/' .. word_start
            .. lower .. one_or_more
            .. upper
            .. word .. '*'
            .. word_end
            .. "<CR>", true, false, true)
        , 'n', false)
end, {})

vim.api.nvim_create_user_command('PascalCase', function()
    -- :h /character-classes
    --   \U = non-upper case, \u = upper case
    --   \L = non-lower case, \l = lower case
    --   OR condition (basically needs all chars escaped): \(\d\|\l\)

    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(
            '/' .. word_start
            .. upper
            .. lower_or_digit .. one_or_more
            .. upper
            .. lower
            .. word .. '*'
            .. word_end
            .. "<CR>", true, false, true)
        , 'n', false)
end, {})

function _G.camel_to_snake(str)
    -- Insert an underscore before each uppercase letter (except at the start)
    -- then lowercase the whole string.
    local res = str:gsub('([A-Z])', function(c)
        return '_' .. c:lower()
    end)
    -- Remove a leading underscore that may have been added for the first character
    res = res:gsub('^_', '')
    return res
end

-- vim.api.nvim_create_user_command('SnakeCase', function(opts)
--     local bufnr = vim.api.nvim_get_current_buf()
--     local start_line, end_line
--
--     if opts.line1 and opts.line2 then
--         start_line = opts.line1 - 1 -- zero‑based indexing
--         end_line = opts.line2 - 1
--     else
--         start_line = vim.api.nvim_win_get_cursor(0)[1] - 1
--         end_line = start_line
--     end
--
--     local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
--     for i, line in ipairs(lines) do
--         lines[i] = camel_to_snake(line)
--     end
--     vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, lines)
-- end, { range = true, nargs = 0 })


-- char 17 in rev, 16 base0
vim.api.nvim_create_user_command('SnakeCase', function()
    -- hello_there TestTheFooBar out of this
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_line_1indexed, cursor_col_0indexed = unpack(vim.api.nvim_win_get_cursor(0))

    local line = vim.fn.getline(cursor_line_1indexed)
    if not line then return end

    -- find the big word (keyword) under the cursor
    local line_after = line:sub(cursor_col_0indexed + 1) -- include char under cursor
    local match_after = vim.fn.matchstrpos(line_after, '\\k\\+')
    local start_col_after_b0 = match_after[2]
    local end_col_after_b0_exclusive = match_after[3]

    -- by the way will take the first word after cursor if cursor is not on a word, that sounds useful to me
    local actual_start_col_b0 = 0
    local actual_end_col_b0_exclusive = cursor_col_0indexed + end_col_after_b0_exclusive
    if start_col_after_b0 == 0 then
        local line_before = line:sub(1, cursor_col_0indexed + 1) -- take char under cursor too to simplify search
        local match_before = vim.fn.matchstrpos(line_before:reverse(), '\\k\\+')
        local start_col_before_b0 = match_before[2]
        local end_col_before_b0 = match_before[3]
        -- vim.print({
        --     line_before = line_before,
        --     match_before = match_before,
        --     start_col_before_b0 = start_col_before_b0,
        --     end_col_before_b0 = end_col_before_b0
        -- })
        if start_col_before_b0 ~= 0 then
            error("when looking before - should not happen, only reason to  look back is if cusror char is part of word which would then match at 0 from before string reversed")
        end
        -- starts in line_before, X (end of match) chars before cursor position
        local start_b0 = cursor_col_0indexed - end_col_before_b0 + 1 -- offset 1 for cursor char
        start_b1 = start_b0 + 1
        -- print("looking before: start_b1: " .. start_b1)
    else
        -- word after cursor, so no looking back
        actual_start_col_b0 = cursor_col_0indexed + start_col_after_b0
        start_b1 = actual_start_col_b0 + 1
        -- print("after cursor: start_b1" .. start_b1)
    end

    stop_b1 = actual_end_col_b0_exclusive -- stop is inclusive for sub, so dont add 1
    local word = line:sub(start_b1, stop_b1)
    -- vim.print({ word = word })

    if word == "" then
        error("no word found around, nor after, cursor")
    end


    local snake = camel_to_snake(word)

    local char_before_word = start_b1 - 1
    local char_after_word = stop_b1 + 1
    local updated_line = line:sub(1, char_before_word) .. snake .. line:sub(char_after_word)
    local line_0indexed = cursor_line_1indexed - 1
    vim.api.nvim_buf_set_lines(bufnr, line_0indexed, line_0indexed + 1, false, { updated_line })
end, { range = true, nargs = 0 })




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
vim.o.number = true -- explicitly do not include absolute line #s (for now)
-- relative + number == absolute instead of 0 for current cursor line (rest are relative)

-- *** help gutter settings (global options don't apply here)
vim.api.nvim_create_augroup("HelpNumbers", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = "HelpNumbers",
    pattern = "help",
    command = "setlocal relativenumber number",
})
