-- cursor block in insert:
vim.cmd(":set guicursor=i:block")



vim.cmd([[
    " TODO fix when close the original file doesn't show
    command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                  \ | wincmd p | diffthis
]])

-- *** help
--
-- start typing :help then Ctrl+R, Ctrl+W takes word under cursor
vim.keymap.set('n', '<F1>', ':help <C-R><C-W><CR>', { noremap = true, silent = true })
--
vim.keymap.set('x', '<F1>', 'y:help <C-R>"<CR>', { noremap = true, silent = true })
vim.keymap.set('v', '<F1>', function()
    -- *** in visual mode, press F1 to search for selected text, or select word under cursor
    -- local mode = vim.fn.visualmode()

    -- current visual seletion start/end:
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    -- FYI '<, '> are positions of LAST visual selection (not current)
    -- this is why '<,'> is inserted into command line when you select text! now it makes sense! ' == mark, </> are the mark "register" names
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    -- vim.cmd('normal! gv') -- reselect LAST visual selection ('<,'> marks)

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- print("start/end", vim.inspect(start_pos), "/", vim.inspect(end_pos))
    if start_line == end_line and start_col == end_col then
        -- print("  only one char, expanding selection to word")
        vim.cmd('normal! iw') -- selects word under cursor (since one char alone isn't really a selection and if it is then this won't change it!)
        -- think of this as not requiring user to make simple selections, do it for them
    end

    -- yank selection into " register
    vim.cmd('normal! ""y')

    local search_term = vim.fn.getreg("\"")
    -- print("  search term: '", search_term, "' (w/o single quotes)")
    vim.cmd('help ' .. search_term)
end)

vim.keymap.set('c', '<F1>', function()
    -- *** help for cmdline contents
    local cmdline = vim.fn.getcmdline()

    -- use Ctrl+C to cancel cmdline mode (otherwise help won't show until after you exit cmdline mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), 'n', false)

    -- TODO if mutliple words, take first word that has help? OR word under cursor?
    vim.cmd('help ' .. cmdline, { silent = true })

    -- could attempt to put cmdline back so it can be edited again BUT people wanted help so stay in help, they can always uparrow to get back cmd next time they enter cmdline mode
    -- pointless to put back the cmdline unless someone was just gonna read the start of the help which is doubtfully enough
    -- vim.api.nvim_feedkeys(":", 'n', false)
end)

-- *** quit help on 'q' => see how I feel about this
vim.api.nvim_create_autocmd("FileType", {
    pattern = "help",
    callback = function()
        vim.api.nvim_buf_set_keymap(0, "n", "q", ":q<CR>", { noremap = true, silent = true })
        -- PRN others?
    end,
})


-- *** :Dump vim.g.foo
-- TODO completion for <args>, lua expression completion
-- Am I the only who hates typing :lua print(vim.inspect(...))?
vim.api.nvim_create_user_command('Dump', "lua print(vim.inspect(<args>))", {
    nargs = '*',
    complete = "lua", -- completes like using :lua command
})
-- vim.cmd [[
--     command! -nargs=1 -complete=lua Dump lua print(vim.inspect(<args>))
-- ]]
--

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

    -- when window is closed, stop watching too
    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(vim.g.inspected_win),
        callback = function()
            stop_watching()
        end,
    })
end

-- *** help customization
vim.api.nvim_create_autocmd("FileType", {
    pattern = "help",
    command = "wincmd L" -- open help in vertical split, on the far left side
    -- ==> Ctrl+W, L ==> far left (vertical split)
    -- TODO do I want this to first check existing splits?
})
