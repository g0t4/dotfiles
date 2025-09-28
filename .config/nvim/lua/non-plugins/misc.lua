--
-- TODO split this out into domain speicific OR:
--   keymaps.lua
--   commands.lua
--   etc


-- cursor block in insert:
vim.cmd(":set guicursor=i:block")



vim.cmd([[
    " TODO fix when close the original file doesn't show
    command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                  \ | wincmd p | diffthis
]])


-- TODO can I use nvim-dap / nvim-dap-virtual-text / etc to debug lua/vimscript running in nvim?
function stop_watching()
    if _G.timer then
        _G.timer:stop()
        _G.timer:close()
        _G.timer = nil
    end
    if vim.g.inspected_win then
        vim.api.nvim_win_close(vim.g.inspected_win, true)
    end
end

function start_watching(func)
    local uv = vim.uv
    _G.timer = uv.new_timer()

    _G.timer:start(0, 1000, vim.schedule_wrap(function()
        show_variable_in_float(func())
    end))
end

-- start_watching(function() return vim.g.watch_me end)

function show_variable_in_float(var_content)
    -- ensure buffer exists with content
    if vim.g.inspected_buf == nil then
        vim.g.inspected_buf = vim.api.nvim_create_buf(false, true)
    end
    local inspected = vim.inspect(var_content)
    vim.api.nvim_buf_set_lines(vim.g.inspected_buf, 0, -1, false, vim.split(inspected, "\n"))

    if vim.g.inspected_win then
        if vim.api.nvim_win_is_valid(vim.g.inspected_win) then
            -- stop if window already open
            return
        end
        -- IIAC is_valid means I need to create a new window? or is there a case when its just closed and needs to be reopened?
    end

    vim.g.inspected_win = vim.api.nvim_open_win(vim.g.inspected_buf, true, {
        relative = "editor",
        width = 50,
        height = 10,
        row = 3,
        col = 3,
        border = "single",
    })
    -- set wrap, for some reasonm it doesn't work if set before opening the window?
    vim.api.nvim_buf_set_option(vim.g.inspected_buf, 'wrap', true)

    vim.api.nvim_create_augroup("FloatWinClose", { clear = true })

    -- when window is closed, stop watching too
    vim.api.nvim_create_autocmd("WinClosed", {
        group = "FloatWinClose",
        pattern = tostring(vim.g.inspected_win),
        callback = function()
            stop_watching()
        end,
    })
end

-- print(_G["setup_workspace"])
-- if type(_G["setup_workspace"]) ~= "function" then
--     vim.notify "setup_workspace should be defined (so that session is restored before loading misc.lua), else help windows will be rearranged (to the right) when they are restored"
-- end

-- *** help customization
vim.cmd.cnoreabbrev({ "<expr>", "h", "v:lua.abbrev_h()" })
function abbrev_h()
    -- new tab for help
    local cmdtype = vim.fn.getcmdtype()
    local cmdline = vim.fn.getcmdline()
    if cmdtype == ":" and cmdline == "h" then
        return 'tab h'
    else
        return 'h'
    end
end

vim.cmd.cnoreabbrev({ "<expr>", "vh", "v:lua.abbrev_vh()" })
function abbrev_vh()
    local cmdtype = vim.fn.getcmdtype()
    local cmdline = vim.fn.getcmdline()
    if cmdtype == ":" and cmdline == "vh" then
        return 'vert h'
    else
        return 'vh'
    end
end

-- *** win splits
-- vim.opt.splitbelow = true -- i.e. help opens below then
vim.opt.splitright = true -- :vsplit now opens new window on the right, I def want that as I always flip them, also Ctrl+V in telescope opens file to the right

vim.keymap.set("n", "<leader>ml", function()
    -- turn the current big Word into a markdown link
    --    use link in the clipboard

    pcall(vim.cmd, 'normal ysiW]Ea(\27pa)')
    -- STEPS:
    -- ysiW] - surrounds text with []
    -- then ( starts the parens after for link
    -- p pastes link from clippy
    -- a) appends closing parens
    --
    -- FYI might be easier to copy current word and build link in code and paste it over the top :)
    --   above was heavily inspired by recording a macro first
end, { noremap = true, silent = true })


-- *** clipboard keymaps
vim.keymap.set("n", "<leader>v", function()
    vim.cmd("normal o") -- insert line after
    vim.cmd("normal O") -- insert line before
    vim.cmd("normal 0p`[v`]=") -- 0 = jump line start, p = paste,
    -- select text => `[ = jump paste start, v = visual mode, `] = jump paste end
    -- re-indent => =
    vim.cmd("normal `[v`]") -- reselect text so you can further modify it
    -- FYI leaves text selected so you can further modify it
end, { noremap = true }) --   0p  - paste from register 0
--   `[  - goto pasted text's start mark (start of last yanked/changed text)
--   v   - charwise visual mode
--   `]  - goto pasted text's end mark (end of last yanked/changed text)
vim.keymap.set("n", "<leader>vc", function()
    -- paste then toggle comments (on/off depending on what you are pasting and if its already commented out)
    -- for some reason, when rhs is just the string of keys... it doesn't comment the lines (or at least not reliably)
    --   but if I call normal w/ same keys it works (so far):
    vim.cmd("normal o") -- insert line after
    vim.cmd("normal O") -- insert line before
    vim.cmd("normal 0p`[v`]gc") -- 0 = jump line start, p = paste, `[ = jump paste start, v = visual mode, `] = jump paste end, gc = toggle comment
    vim.cmd("normal gv=") -- then reindent (reselect, indent)
    -- PRN re-select?
end, { noremap = true }) -- " and comment it out (toggle comment)
-- PRN I could drop vc and just get in habit of vgc which is nearly the same
vim.keymap.set("n", "<leader>vj", function()
    -- paste as json codeblock in markdown... could check that and/or other file details?
    -- PRN... would be neat to detect file type in clipboard and put appropriate name at start of block?
    --     that way I don't need permutations of this for other languages...
    --     or put cursor at top of block for me to type in the type?

    -- TODO try using vim.api.nvim_put( lines...) where lines is a table of lines -- AFAICT don't want \n in the lines
    -- ```
    vim.cmd("normal o") -- insert line after
    -- FYI don't need to worry about start of line comment in a markdown file when inserting a new codeblock, no concept of a comment AFAIK in markdown
    vim.cmd("normal 0i```") -- closing markdown code block

    -- ```json
    vim.cmd("normal O") -- insert line before
    vim.cmd("normal 0i```json") -- opening markdown code block

    -- paste and indent
    vim.cmd("normal o") -- insert line after
    vim.cmd("normal p`[v`]=") -- while on line above paste spot... paste and indent
    -- TODO if it comes up a lot, use regtype to detect linewise/charwise/blockwise
end, { noremap = true }) -- " and comment it out (toggle comment)


-- *** open in ... => quickly toggle to other editors
vim.api.nvim_create_user_command('CodeHere', function()
    -- to trigger you!
    local filename = vim.fn.expand("%:p")
    local row_1based, col_0based = unpack(vim.api.nvim_win_get_cursor(0))
    local cwd = vim.fn.getcwd()
    local command = "code " .. cwd .. " --goto " .. filename .. ":" .. row_1based .. ":" .. (col_0based + 1)
    vim.fn.system(command)
end, {})

vim.api.nvim_create_user_command('ZedHere', function()
    local filename = vim.fn.expand("%:p")
    local row_1based, col_0based = unpack(vim.api.nvim_win_get_cursor(0))
    local command = "zed " .. filename .. ":" .. row_1based .. ":" .. (col_0based + 1)
    vim.fn.system(command)
end, {})




-- *** CASE helpers

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
    -- PRN add tests if I wanna work on this further
    -- insert underscore before each uppercase letter
    local res = str:gsub('([A-Z])', function(c)
        -- then lowercase the whole string.
        return '_' .. c:lower()
    end)
    -- Remove leading underscore (if added for initial capital letter)
    res = res:gsub('^_', '')
    return res
end

vim.api.nvim_create_user_command('SnakeCase', function()
    -- PRN add tests if I wanna work on this further
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
