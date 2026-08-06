local M = {}
local LUA_IDSIZE = 60
function M.lua_short_path(path, idsize)
    idsize = idsize or LUA_IDSIZE
    local max_length = idsize - 1
    if #path <= max_length then
        return path
    end
    return "..." .. path:sub(-(max_length - 3))
end

local function split(path)
    local components = {}
    for component in path:gmatch("[^/]+") do
        table.insert(components, component)
    end
    return components
end

local function regex_escape(s)
    return (s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end


local cached_fixes = {}

function M.resolve_truncated_path(workspace_root, truncated_path)
    if cached_fixes[truncated_path] then
        print("  CACHED: " .. cached_fixes[truncated_path])
        return cached_fixes[truncated_path]
    end

    local trunc_without_dots = truncated_path:gsub("%.%.%.", "")
    print("  " .. trunc_without_dots)

    local try_roots = {
        workspace_root,
        os.getenv("HOME") .. "/.local"
    }

    ---@param root string
    local function try_find(root)
        local cmd = {
            "fd",
            "--type", "f",
            "--absolute-path",
            "--full-path",
            "--fixed-strings",
            trunc_without_dots,
            root
        }

        local result = vim.system(cmd, { text = true }):wait()
        return result
    end
    -- TODO take package.path and extract paths to check after cwd?
    -- vim.print(table.concat(cmd, " "))

    for _, root in ipairs(try_roots) do
        local result = try_find(root)

        if result.code == 0 then
            local matches = {}

            for path in result.stdout:gmatch("[^\r\n]+") do
                matches[#matches + 1] = path
            end

            if #matches == 1 then
                local matched = matches[1]
                local match_truncated = M.lua_short_path(matched)
                if match_truncated == truncated_path then
                    cached_fixes[truncated_path] = matched
                    return matched
                end
                return nil
            elseif #matches > 1 then
                -- PRN allow? take first or?
                print("  multi matches: " .. vim.inspect(matches))
                error("  unexpected multiple matches, TODO add support if you have real example to work through... truncated_path: " .. vim.inspect(truncated_path))
            end
        end
    end

    return nil
end

return M
