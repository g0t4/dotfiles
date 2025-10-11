require('non-plugins.werkspaces.filetypemods') -- FYI! must load  before werkspace else filetype mods dont fire for initial opened buffer
-- actually not the end of the world to tie these two together, they are similar in what they acccomplish
-- TODO can I fix so filetypmods are applied to existing buffers on load?

local nvim = require("non-plugins.nvim")

if nvim.is_headless() then
    if nvim.is_running_plenary_test_harness() then
        -- don't log extra messages when testing
        return
    end
    print("werkspace will not load in headless mode")
    return
end

function is_lazy_open()
    local win_ids = vim.api.nvim_list_wins()

    return vim.iter(win_ids)
        :map(
            function(win_id)
                local buf_id = vim.api.nvim_win_get_buf(win_id)
                return vim.api.nvim_buf_get_option(buf_id, "filetype")
            end)
        :any(function(ft) return ft == "lazy" end)
end

function setup_workspace()
    -- dir or nil
    local function get_git_root()
        local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
        if handle then
            local git_root = handle:read("*line")
            handle:close()
            return git_root
        end
        return nil
    end

    -- PRN should I use a global shada file if not in a repo?
    local dir = get_git_root() or vim.fn.getcwd()
    local hash = vim.fn.sha256(dir)
    -- TODO sha256 takes 10ms to run :( ... faster way? what does vscode use, doesn't it store some workspace state centrally?
    local workspaces_dir = "~/.config/nvim/shada/workspaces/"
    workspaces_dir = vim.fn.expand(workspaces_dir) -- expand ~, else it will be literally ~ and yeah not what you want
    local shada_path = workspaces_dir .. hash .. "/shada"

    -- WHY do this with shada:
    --   privacy (don't jump list back to another project, i.e. during screencast)
    --   separate workspaces, jumplist/marks s/b per project, not global... like vscode
    --      and cmd history, also belongs per project (though I can see more of an argument for global cmd history but since I don't use it much I don't think it will matter)
    vim.opt.shadafile = shada_path


    vim.g.session_file = workspaces_dir .. hash .. "/session.vim"
    --
    vim.cmd [[

        " removing buffers (I don't want background buffers, I can add back if I want that later)
        " removing curdir (this is dervied by convention, dont want that changing, session is stored PER cwd so no need to change curdir)
        " removing terminal (I don't want to restore terminals, I can add back if I want that later)
        " PRN do I wanna remove blank?
        set sessionoptions=blank,folds,help,tabpages,winsize

        function EraseSession()
            " preserves shada! i.e. cmd history to call this func!
            if !filereadable(g:session_file)
                return
            endif
            call delete(g:session_file)
        endfunction

        function QuitWithEraseSession()
            call EraseSession()
            call QuitWithoutSavingSession()
        endfunction

        function QuitWithoutSavingSession()
            augroup SaveSessionOnQuit
                autocmd!
            augroup END
            quitall
        endfunction

        function RestoreSession()

            " capture passed files BEFORE session overwrites them which is ... WTH? why?
            "    session argv() is always the args for the very first time the session was loaded! yikez (first save since not restoring a prev session)
            "    what else is like this, that might cause issues?
            let files_before_load = argv()
            " what do I really need in a session besides restore last file? and maybe that's it?
            if !filereadable(g:session_file)
                return
            endif

            try
                execute "source" g:session_file
            catch
                " known issue => session has help file for lazy loaded extension (i.e. nvim-tree) and so the help page doesn't exist on next startup b/c nvim-tree only loads when you open it
                " TODO is there a situation when vim.v.exception/throwpoint is nil and would cause this to fail?
                lua vim.notify("Session Restore FAILED" .. "\n\n" .. vim.v.exception .. "\n\n" .. vim.v.throwpoint, "error", { title = "Session Restore", render = "wrapped-compact" })
                " on failure, user can save a new one to fix in most cases there is no need to troubleshoot much
            endtry

            " open any files passed to nvim, after loading session, mimic vscode behavior
            if len(files_before_load) > 0
                for file in files_before_load
                    execute "edit" file
                endfor
            endif

            lua FocusLastFocusedFile()

        endfunction

        " TODO add keymap for save session? (think save conventional session file)
        function OnLeaveSaveSession()
            " TODO move all window close logic to the lua func below
            " if :NvimTreeClose command is defined, call it:
            if exists(":NvimTreeClose")
                NvimTreeClose
            endif
            lua werkspaces_close_tmp_windows_to_not_reopen_them()

            call SaveSession()
        endfunction

        function SaveSession()
            execute "mksession!" g:session_file
            lua AppendLastFocusedFileToSession()
        endfunction

        function SaveSessionWithNotify()
            call SaveSession()
            lua vim.notify("Saved", "info", { title= "Session Saved", timeout = 500 }) -- briefly show only
        endfunction
        nnoremap <silent> <F6> :call SaveSessionWithNotify()<CR>

        " i.e. change to diff files temp (brief tangent) and wanna go back to what I had when opened vim (dont wanna open new tab, and come back and close current instance just to restore and keep prior saved session)
        function RestoreSessionWithNotify()
            call RestoreSession()
            lua vim.notify("Restored", "info", { title= "Session Restored", timeout = 500 }) -- briefly show only
        endfunction
        nnoremap <silent> <F7> :call RestoreSessionWithNotify()<CR>

        function OnLeaveSaveWindowState()
            if ! exists('$IS_SEMANTIC_WINDOW')
                return
            endif
            " TODO! confirm still works after rearranging nvim non-plugin config

            " 20ms+ to send via new python process, not surprising
            "!uv run "/Users/wes/repos/github/g0t4/dotfiles/iterm2/semantic-click-handler/quit-client.py" $ITERM_SESSION_ID
            " ZERO lag using lua to send the notification... as expected
            lua require("non-plugins.werkspaces.semantic-client").NotifyDaemonOfSessionQuit()
        endfunction
    ]]
    --
    -- -- Session notes:
    -- --   what if I pass file names to nvim, shouldn't I also open those in addition to whatever is open as of last session save?
    -- --   if open multiple instances, all bets are off but that is fine b/c its rare (usually just if I wanna test dotfiles w/o quitting nvim editing instance)... also vscode always would reopen in already open instance so I dont know there is any logic for multiple instances when there is a "shared" session...
    -- --   I LOVE RESUMING the last open file!!!

    if not is_lazy_open() then
        vim.cmd [[
            call RestoreSession()
            " instead of auto load session, can use Ctrl+I to go back to last file
            " new comment coloring with treesitter queries seems to work fine w/ session restore
            " FYI old regex syntax based comment colors were a hot mess when loading sessions (never colored initial buffer/files correctly)

            augroup SaveSessionOnQuit
                autocmd!
                autocmd VimLeavePre * call OnLeaveSaveSession()
                autocmd VimLeavePre * call OnLeaveSaveWindowState()
            augroup END

            augroup SaveLastFocusedFile
                " TODO not running on startup, only on focus changed
                autocmd!
                autocmd WinEnter * lua vim.g.last_focused_file = vim.fn.bufname(vim.fn.winbufnr(0))
            augroup END
        ]]
    else
        vim.notify("Lazy open => no session restore / autosave, restart to restore prior session", vim.log.levels.WARN)
    end
end

function FocusLastFocusedFile()
    if not vim.g.last_focused_file then
        -- print('no last file')
        return
    end
    -- TODO support multiple windows w/ same file open? viminfo/shada successfully stores and restores folds/position info in this case, so I can certainly find a way to restore focus!
    -- FYI this only works for first tab focus, fine with me as I don't use tabs much yet
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf_id                = vim.api.nvim_win_get_buf(win)
        -- tested w/ help left open too, works b/c help is a file
        local buf_name              = vim.fn.bufname(buf_id)
        -- PRN add a check if not a file/path? if I encounter that issue then do this
        local buf_abs_path          = vim.fn.fnamemodify(buf_name, ':p')
        -- print("win: " .. win .. " buf_id: " .. buf_id .. " buf_name: " .. buf_name .. " buf_abs_path: " .. buf_abs_path)
        local last_focused_abs_path = vim.fn.fnamemodify(vim.g.last_focused_file, ':p')
        -- print("  lff: " .. last_focused_abs_path)
        if buf_abs_path == last_focused_abs_path then
            -- print(" found last focused window: " .. win)
            vim.schedule(function()
                -- for some reason, only on startup, it won't switch windows without a schedule delay
                -- doesn't hurt to leave it this way always (for session restore without restart nvim)
                vim.api.nvim_set_current_win(win)
            end)
            break
        end
    end
end

function AppendLastFocusedFileToSession()
    -- tail session.vim to check this
    -- assume session.vim already created with mksession
    local buf_id = vim.fn.winbufnr(0)
    local file_path = vim.fn.bufname(buf_id)
    if file_path and file_path ~= '' then
        vim.g.last_focused_file = file_path
        -- TODO isn't this already expanded?
        local session_file = vim.fn.expand(vim.g.session_file)
        -- TODO check if exists to be safe?
        if session_file then
            vim.fn.writefile({ "let g:last_focused_file = '" .. file_path .. "'" }, session_file, "a")
        end
    end
end

setup_workspace()

-- *** I probably don't need this, nor should I have it... but just an idea to see how I feel...
-- *** basically only gonna apply when I first open a project/werkspace and there are no prior files open (or exit with a new file only open)
--     HENCE it would be fine to nuke all this
function IsSingleNewFileWindowOnly()
    local windows = vim.api.nvim_tabpage_list_wins(0) -- get all windows in current tab only
    local eligible_window_buf = nil

    for _, win in ipairs(windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)

        -- Skip windows related to Wilder or any other ignoreable buffers (i.e. float windows, esp if not opened yet)
        if not buf_name:match("Wilder") then
            if eligible_window_buf then
                return false -- More than one eligible window
            else
                eligible_window_buf = buf
            end
        end
    end

    -- -- TODO try out penlight for functional programming in lua, or Lua Fun, or Moses, or?
    -- local seq = require('pl.seq')
    -- local tbl = { 1, 2, 3 }
    -- local result = seq(tbl) -- wrap the table
    --     :map(function(x) return x * 2 end)
    --     :filter(function(x) return x > 2 end)
    --     :totable() -- convert back to a plain table
    -- print(result) -- {4, 6}

    if eligible_window_buf then
        local filename = vim.api.nvim_buf_get_name(eligible_window_buf)
        return filename == "" or vim.fn.filereadable(filename) == 0 -- empty or non-existent file
    end
    return false
end

function OpenTreeIfSingleNewFileWindowOnly()
    if IsSingleNewFileWindowOnly() then
        -- dispatch <C-l> to open tree view (its lazy loaded)
        require("nvim-tree")
        vim.cmd("NvimTreeOpen")
    end
end

OpenTreeIfSingleNewFileWindowOnly()
