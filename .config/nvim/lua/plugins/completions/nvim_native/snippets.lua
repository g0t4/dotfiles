-- Offer personal LuaSnip snippets through Neovim's built-in completion menu.
local M = {}

function M.complete(findstart, base)
    if findstart == 1 then
        local before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
        return #before - #(before:match("[%w_#*@=]+$") or "")
    end

    local snippets = require("luasnip")
    local matches = {}
    for _, filetype in ipairs(snippets.get_snippet_filetypes()) do
        for index, snippet in ipairs(snippets.get_snippets(filetype)) do
            if snippet.trigger:sub(1, #base) == base then
                matches[#matches + 1] = {
                    word = snippet.trigger,
                    abbr = snippet.trigger,
                    menu = "[snippet] " .. (snippet.name or ""),
                    user_data = { native_snippet = { filetype = filetype, index = index } },
                }
            end
        end
    end
    return matches
end

function M.setup()
    -- 'F' uses completefunc and 'o' uses the LSP omnifunc.
    vim.o.completefunc = "v:lua.require'plugins.completions.nvim_native.snippets'.complete"
    vim.o.complete = "F,o"
    vim.o.autocomplete = true

    vim.api.nvim_create_autocmd("CompleteDone", {
        group = vim.api.nvim_create_augroup("native_snippet_completion", { clear = true }),
        callback = function()
            if vim.v.event.reason ~= "accept" then return end
            local choice = vim.tbl_get(vim.v.completed_item, "user_data", "native_snippet")
            if not choice then return end
            local snippet = require("luasnip").get_snippets(choice.filetype)[choice.index]
            if not snippet then return end
            local bufnr = vim.api.nvim_get_current_buf()
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then return end
                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                local start = col - #snippet.trigger
                if start < 0 or vim.api.nvim_get_current_line():sub(start + 1, col) ~= snippet.trigger then return end
                require("luasnip").snip_expand(snippet, {
                    clear_region = { from = { row - 1, start }, to = { row - 1, col } },
                })
            end)
        end,
    })
end

return M
