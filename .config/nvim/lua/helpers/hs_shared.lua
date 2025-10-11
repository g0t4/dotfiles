--- TODO, these could be shared with hammerspoon, but for now let's keep them distinct
-- FYI! hammerspoon has a copy of these too

--- aggresive sanitizer
---@param name string
---@return string name -- sanitized, can be used in a filename
function sanitize_for_filename(name)
    -- replace if not alphanumeric (%w) or a literal dot/dash
    name = name:gsub("[^%w_%-%.]", "_")

    -- trim leading and trailing whitespace
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")

    return name
end
