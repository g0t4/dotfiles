local M = {}

--- get git repo root, if in a git repo
---@return string? path
local function get_git_root()
    local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
    if handle then
        local git_root = handle:read("*line")
        handle:close()
        return git_root
    end
    return nil
end

--- Directory opened in neovim with the user's files, either:
--- - If in a git repo, the repo root directory
--- - Or, CWD
---@return string path
function M.get_werkspace_root_dir()
    return get_git_root() or vim.fn.getcwd()
end

--- Directory to store werkspace's shada, sessions, etc
---@return string path
function M.get_werkspace_state_dir()
    local dir = M.get_werkspace_root_dir()

    local hash = vim.fn.sha256(dir) -- 10ms, not terrible and I've never really noticed startup impact
    local werkspaces_dir = "~/.config/nvim/shada/werkspaces/"
    werkspaces_dir = vim.fn.expand(werkspaces_dir)
    return werkspaces_dir .. hash
end

---@param relative_path string
---@return table|nil decoded
function M.read_json_werkspace_file(relative_path)
    local abs_path = vim.fn.expand(M.get_werkspace_state_dir() .. "/" .. relative_path)
    local ok, lines = pcall(vim.fn.readfile, abs_path)
    if not ok or not lines or #lines == 0 then
        return nil
    end
    local decoded_ok, data = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
    if decoded_ok and type(data) == "table" then
        return data
    end
    return {}
end

---@param relative_path string
---@param object table
function M.write_json_werkspace_file(relative_path, object)
    local encoded = vim.fn.json_encode(object)
    local abs_path = vim.fn.expand(M.get_werkspace_state_dir() .. "/" .. relative_path)
    vim.fn.mkdir(vim.fn.fnamemodify(abs_path, ":h"), "p")
    vim.fn.writefile(encoded, abs_path)
end

return M
