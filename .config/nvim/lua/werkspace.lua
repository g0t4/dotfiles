local function setup_workspace()
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
    local workspace_dir = "~/.config/nvim/shada/workspaces/"
    workspace_dir = vim.fn.expand(workspace_dir) -- expand ~, else it will be literally ~ and yeah not what you want
    local shada_path = workspace_dir .. hash .. "/shada"

    -- WHY do this with shada:
    --   privacy (don't jump list back to another project, i.e. during screencast)
    --   separate workspaces, jumplist/marks s/b per project, not global... like vscode
    --      and cmd history, also belongs per project (though I can see more of an argument for global cmd history but since I don't use it much I don't think it will matter)
    vim.opt.shadafile = shada_path


    vim.g.session_file = workspace_dir .. hash .. "/session.vim"
    --
    vim.cmd [[

        " removing buffers (I don't want background buffers, I can add back if I want that later)
        " removing curdir (this is dervied by convention, dont want that changing, session is stored PER cwd so no need to change curdir)
        " removing terminal (I don't want to restore terminals, I can add back if I want that later)
        " PRN do I wanna remove blank?
        set sessionoptions=blank,folds,help,tabpages,winsize

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
                lua require('notify').notify("Session Restore FAILED".. "\n\n" .. vim.v.exception .. "\n\n" .. vim.v.throwpoint, "error", { title = "Session Restore", render = "wrapped-compact"})
                " on failure, user can save a new one to fix in most cases there is no need to troubleshoot much
            endtry

            " open any files passed to nvim, after loading session, mimic vscode behavior
            if len(files_before_load) > 0
                for file in files_before_load
                    execute "edit" file
                endfor
            endif

        endfunction

        call RestoreSession()
        " instead of auto load session, can use Ctrl+I to go back to last file
        " new comment coloring with treesitter queries seems to work fine w/ session restore
        " FYI old regex syntax based comment colors were a hot mess when loading sessions (never colored initial buffer/files correctly)

        autocmd VimLeavePre * call OnLeaveSaveSession()

        " TODO add keymap for save session? (think save conventional session file)
        function OnLeaveSaveSession()
            " if :NvimTreeClose command is defined, call it:
            if exists(":NvimTreeClose")
                NvimTreeClose
            endif

            call SaveSession()
        endfunction

        function SaveSession()
            execute "mksession!" g:session_file
        endfunction

    ]]
    --
    -- -- Session notes:
    -- --   what if I pass file names to nvim, shouldn't I also open those in addition to whatever is open as of last session save?
    -- --   if open multiple instances, all bets are off but that is fine b/c its rare (usually just if I wanna test dotfiles w/o quitting nvim editing instance)... also vscode always would reopen in already open instance so I dont know there is any logic for multiple instances when there is a "shared" session...
    -- --   I LOVE RESUMING the last open file!!!
end

setup_workspace()
