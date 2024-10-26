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

    local session_file = workspace_dir .. hash .. "/session.vim"

    -- Load session on startup
    if vim.fn.filereadable(vim.fn.expand(session_file)) == 1 then
        print("Loading session: " .. session_file)
        vim.cmd("source " .. session_file)
    end

    -- Save session on exit
    vim.cmd("autocmd VimLeavePre * mksession! " .. session_file)
    -- DO NOT SAVE nvim-tree window or do? currently messing up reloading session :(... this is what I wanted to find so I can go hunting for a plugin or tweak my config ... keep taking notes

    -- Session notes:
    --   what if I pass file names to nvim, shouldn't I also open those in addition to whatever is open as of last session save?
    --   if open multiple instances, all bets are off but that is fine b/c its rare (usually just if I wanna test dotfiles w/o quitting nvim editing instance)... also vscode always would reopen in already open instance so I dont know there is any logic for multiple instances when there is a "shared" session...
    --   I LOVE RESUMING the last open file!!!
end

setup_workspace()
