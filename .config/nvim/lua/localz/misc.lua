-- cursor block in insert:
vim.cmd(":set guicursor=i:block")



vim.cmd([[
    " TODO fix when close the original file doesn't show
    command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                  \ | wincmd p | diffthis
]])

-- *** quit help on 'q' => see how I feel about this
vim.api.nvim_create_autocmd("FileType", {
    pattern = "help",
    callback = function()
        vim.keymap.set("n", "q", ":q<CR>", { noremap = true, silent = true, buffer = true })
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
    " vertical split help:
    cnoreabbrev h vert h
    "
    " horiz split (or otherwise not prepend vert)
    cnoreabbrev H h
    " TODO this all feels wrong, but works for now maybe
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
