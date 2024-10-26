local function set_shada_for_workspace()
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
    local shada_path = "~/.local/share/nvim/shada/workspaces/" .. hash .. ".shada"
    -- TODO refactor to put auto sessions here too? probably rename to drop "shada" or at least make the hash available so not need to recompute

    vim.opt.shadafile = shada_path
end

-- WHY do this?
--   privacy (don't jump list back to another project, i.e. during screencast)
--   separate workspaces, jumplist/marks s/b per project, not global... like vscode
--      and cmd history, also belongs per project (though I can see more of an argument for global cmd history but since I don't use it much I don't think it will matter)
--   should work well with some sort of auto session save config/plugin that tracks a session in accordance with this workspace dir too.. so I can reuse the hash file above
set_shada_for_workspace()
