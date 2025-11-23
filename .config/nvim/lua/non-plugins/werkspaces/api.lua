local M = {}

---@return string
function M.get_werkspace_dir()
    local function get_git_root()
        local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
        if handle then
            local git_root = handle:read("*line")
            handle:close()
            return git_root
        end
        return nil
    end

    local dir = get_git_root() or vim.fn.getcwd()
    local hash = vim.fn.sha256(dir) -- 10ms, not terrible and I've never really noticed startup impact
    local werkspaces_dir = "~/.config/nvim/shada/werkspaces/"
    werkspaces_dir = vim.fn.expand(werkspaces_dir)
    return werkspaces_dir .. hash
end

return M
