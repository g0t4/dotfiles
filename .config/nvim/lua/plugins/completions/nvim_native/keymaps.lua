local M = {}

local function selected_matches(info)
    if info.selected < 0 or not info.completed then return false end
    for _, item in ipairs(info.items) do
        if item.match and item.word == info.completed.word
            and vim.deep_equal(item.user_data, info.completed.user_data) then return true end
    end
    return false
end

function M.break_undo()
    -- Unlike <C-g>u, this leaves an active completion menu open.
    vim.bo.undolevels = vim.bo.undolevels
end

function M.setup(opts)
    opts = opts or {}
    vim.keymap.set('i', '<CR>', function()
        if vim.fn.pumvisible() == 0 then return '<CR>' end
        local info = vim.fn.complete_info({ 'selected', 'completed', 'items', 'matches' })
        return selected_matches(info) and '<C-y><C-g>u' or '<C-e><CR>'
    end, { expr = true, silent = true, desc = 'Accept selected completion or insert newline' })
    vim.keymap.set('i', '<S-CR>', function()
        return vim.fn.pumvisible() == 1 and '<C-e>' or '<S-CR>'
    end, { expr = true, silent = true, desc = 'Dismiss completion' })
    local group = vim.api.nvim_create_augroup('native_completion_undo', { clear = true })
    local active = {}
    vim.api.nvim_create_autocmd('CompleteChanged', {
        group = group,
        callback = function(args)
            local first = not active[args.buf]
            local tick = vim.api.nvim_buf_get_changedtick(args.buf)
            if not first and active[args.buf] == tick then return end
            active[args.buf] = tick
            -- Start before navigation inserts a candidate. Completion-mode keys
            -- such as C-n are handled by Nvim itself, bypassing insert mappings.
            if first then M.break_undo() end
            if opts.auto_select then
                local bufnr, tick = args.buf, vim.api.nvim_buf_get_changedtick(args.buf)
                vim.schedule(function()
                    if vim.api.nvim_get_current_buf() ~= bufnr
                        or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick
                        or vim.fn.pumvisible() == 0 then return end
                    local info = vim.fn.complete_info({ 'selected', 'completed', 'items', 'matches' })
                    local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
                    local matches = vim.tbl_filter(function(item) return item.match end, info.items)
                    if not selected_matches(info) and #matches > 0 and before:match('%S$') then
                        -- A hidden selection survives fuzzy filtering in Nvim.
                        -- Move past it to the original text, then the first match.
                        local keys = info.selected >= 0 and '<Down><Down>' or '<Down>'
                        -- Down highlights without inserting the candidate text.
                        vim.api.nvim_feedkeys(vim.keycode(keys), 'in', false)
                    end
                end)
            end
        end,
    })
    vim.api.nvim_create_autocmd('CompleteDone', {
        group = group,
        callback = function(args)
            active[args.buf] = nil
            if vim.v.event.reason ~= 'accept' then return end
            -- Personal snippets expand on the next tick and close their own block.
            if vim.tbl_get(vim.v.completed_item, 'user_data', 'native_snippet') then return end
            local bufnr, tick = args.buf, vim.api.nvim_buf_get_changedtick(args.buf)
            vim.schedule(function()
                if vim.api.nvim_get_current_buf() == bufnr
                    and vim.api.nvim_buf_get_changedtick(bufnr) == tick then
                    M.break_undo()
                end
            end)
        end,
    })
end

return M
