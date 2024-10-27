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
    -- TODO refactor to put auto sessions here too? probably rename to drop "shada" or at least make the hash available so not need to recompute

    -- WHY do this with shada:
    --   privacy (don't jump list back to another project, i.e. during screencast)
    --   separate workspaces, jumplist/marks s/b per project, not global... like vscode
    --      and cmd history, also belongs per project (though I can see more of an argument for global cmd history but since I don't use it much I don't think it will matter)
    vim.opt.shadafile = shada_path


    -- TODO reduce what the session is tracking, it's breaking color changes (seems to hold onto old hl groups or smth... very confusing to troubleshoot changes)
    --    vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize"
    --
    --    # currently my sessionoptions: (so why then is it messing up color changes?)
    --    # sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,terminal
    --
    --    # or do I need smth like redraw()? require("lazy").redraw()? chatgpt suggested, no idea wtf this is and why it would be needed?
    --
    --
    vim.g.session_file = workspace_dir .. hash .. "/session.vim"
    --
    --
    --
    vim.cmd [[

        function LoadSession()
            if !filereadable(g:session_file)
                echo "No session file found: " . g:session_file
                return
            endif

            execute "source" g:session_file
        endfunction

        " TODO re-enable load session automatically?
        "call LoadSession()
        " for now I can use jump history to go back to last spot (and its project specific so it will work great w/o loading session)
        " FYI I disabled loading session when troubleshooting color issues which it was adding confusion to
        "    TODO ... I suspect the issue with thinking colors are messed up was that with sessions I load the laast used doc where I dont see colors but that is due to my bug that requires reload or switch files after whhich colors work and its not sessions
        "       NOT ENTIRELY => cuz w/ session restored, I can't reload doc to fix it, with ":e!" so it is something with sessions too, whereas w/o calling loadSession() it can be reloaded with ":e!" to get comments highlighted

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
