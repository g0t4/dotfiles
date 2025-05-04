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
    local uv = vim.loop
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

-- *** help customization
-- print(_G["setup_workspace"])
-- if type(_G["setup_workspace"]) ~= "function" then
--     vim.notify "setup_workspace should be defined (so that session is restored before loading misc.lua), else help windows will be rearranged (to the right) when they are restored"
-- end
-- FYI I switched away from BufEnter => Ctrl+W,L b/c it resized already open help and I don't like that and WinNew won't suffice b/c doesn't have filetype to only trigger first time win opens.. so use abbr instead, I like this so far
vim.cmd [[
    " TODO see how I feel about this, not sure I like it, wish it didn't involve changing the cmd line,
    "   PRN I could redefine h/help to call vert h... and then set command-complete too to make completion work
    " only downside is trying to use H alone in a command line also expands, can use Ctrl+V=>Space to avoid expanding it
    "
    " * vertical split help:
    " - always expand, anywhere in cmdline:
    " cnoreabbrev h vert h
    " i.e:    foo h<SPACE> => foo vert h  (YUCK)
    "
    " - donesn't double expand:
    cabbrev <expr> h getcmdtype() == ':' && getcmdline() == 'h' ? 'vert h' : 'h'
    "... IIAC won't work in some cases, if smth comes before h ... not sure that would ever happen, hasn't yet for me
    "
    "   FYI could call lua in an VimL expression (like <expr> ex above):
    "      cabbrev <expr> h v:lua.MyHelpAbbrev()
    "      function MyHelpAbbrev() ... end

    " * horiz split (or otherwise not prepend vert)
    "cnoreabbrev H h
    " TODO this all feels wrong, but works for now maybe


    " FYI can use abbrs to fix common casing mistakes?
    " cnoreabbrev DUmp Dump
    "  could I map a regex or smth so I can match any combo of cases, in effect make my Dump command case insensitive for activation?
]]
--
-- ALTERNATIVE works fine too:
-- vim.api.nvim_create_user_command(
--     'H', -- must be uppercase, gah
--     function(opts)
--         vim.cmd('vert help ' .. opts.args)
--     end,
--     { nargs = "*", complete = "help" }
-- )


-- *** win splits
-- vim.opt.splitbelow = true -- i.e. help opens below then
vim.opt.splitright = true -- :vsplit now opens new window on the right, I def want that as I always flip them, also Ctrl+V in telescope opens file to the right

-- *** WIP CmdCapture
-- TODO how is this not a builtin thing? or is it? (redir + cmd + paste?)
-- i.e. `:CmdCapture nmap <leader>` => new buffer, then :sort if desired to find what keymaps are avail
-- this is like :Dump, a command means its just one word before what I want to run to add this special behavior below
vim.api.nvim_create_user_command('CmdCapture', "lua CaptureCommandOutput(<q-args>)", {
    nargs = '*',
    -- TODO can I specify the entire argument is a command and get completion on the ex command args too?
    -- FOR now, type command first and then prepend :CmdCapture (maybe add a keybind to do this)
    complete = "command", -- :help :command-complete
})
function CaptureCommandOutput(cmd)
    vim.cmd('new')
    local output = vim.fn.execute(cmd)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, '\n'))
end

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
