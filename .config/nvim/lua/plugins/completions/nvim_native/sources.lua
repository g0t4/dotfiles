local M = {}

-- 'autocomplete' invokes the omnifunc even after whitespace edits. Keep
-- explicit Ctrl-Space requests on vim.lsp.completion.get(), which bypasses this.
function M.omnifunc(findstart, base)
    local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
    if before == '' or before:match('%s$') then
        return findstart == 1 and -2 or {}
    end
    return vim.lsp.omnifunc(findstart, base)
end

return M
