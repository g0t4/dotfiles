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
    local shada_path = "~/.local/share/nvim/shada/workspaces/" .. hash .. ".shada"

    vim.opt.shadafile = shada_path
end

set_shada_for_workspace()
