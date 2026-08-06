local M = {}

local function lua_short_path(path)
    local idsize = 60
    local max_length = idsize - 1
    if #path <= max_length then
        return path
    end
    return "..." .. path:sub(-(max_length - 3))
end

local cached_fixes = {}
---@param truncated_path string -- path from traceback that starts with ... and is truncated ending of the absolute path
function M.resolve_truncated_path(truncated_path)
    local cached = cached_fixes[truncated_path]
    if cached then
        return cached
    end

    local suffix = truncated_path:gsub("^%.%.%.", "")

    -- FYI technically we don't need workspace_root first, it is probably the best place to look first
    --  unless the errors aren't in your own code
    local workspace_root = vim.fn.getcwd()
    local roots = { workspace_root }
    local seen = { [workspace_root] = true }

    for root in vim.gsplit(vim.o.runtimepath, ",", { plain = true }) do
        root = vim.fn.fnamemodify(root, ":p")

        if not seen[root] then
            seen[root] = true
            table.insert(roots, root)
        end
    end

    for _, root in ipairs(roots) do
        -- print("  CHECKING " .. root)
        local result = vim.system({
            "fd",
            -- "--type", "file",
            "--absolute-path",
            "--full-path",
            "--fixed-strings",
            suffix,
            root,
        }, { text = true }):wait()

        if result.code == 0 then
            local matches = vim
                .iter(vim.gsplit(result.stdout, "\n", { plain = true }))
                :filter(function(path)
                    return path ~= ""
                end)
                :totable()

            if #matches == 1 then
                local match = matches[1]
                if lua_short_path(match) == truncated_path then
                    cached_fixes[truncated_path] = match
                    return match
                end
            elseif #matches > 1 then
                error(("Multiple matches for %q:\n%s"):format(
                    truncated_path,
                    table.concat(matches, "\n")
                ))
            end
        end
    end

    return nil
end

return M
