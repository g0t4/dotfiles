local M = {}

function M.break_undo()
    -- Unlike <C-g>u, this leaves an active completion menu open.
    vim.bo.undolevels = vim.bo.undolevels
end

function M.setup()
    vim.keymap.set('i', '<CR>', function()
        if vim.fn.pumvisible() == 0 then return '<CR>' end
        return vim.fn.complete_info().selected >= 0 and '<C-y><C-g>u' or '<C-e><CR>'
    end, { expr = true, silent = true, desc = 'Accept selected completion or insert newline' })
    vim.keymap.set('i', '<S-CR>', function()
        return vim.fn.pumvisible() == 1 and '<C-e>' or '<S-CR>'
    end, { expr = true, silent = true, desc = 'Dismiss completion' })
    local group = vim.api.nvim_create_augroup('native_completion_undo', { clear = true })
    local active = {}
    vim.api.nvim_create_autocmd('CompleteChanged', {
        group = group,
        callback = function(args)
            if active[args.buf] then return end
            active[args.buf] = true
            -- Start before navigation inserts a candidate. Completion-mode keys
            -- such as C-n are handled by Nvim itself, bypassing insert mappings.
            M.break_undo()
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
