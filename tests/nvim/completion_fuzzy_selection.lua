-- nvim --clean --headless '+luafile tests/nvim/completion_fuzzy_selection.lua'
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/.config/nvim')
require('plugins.completions.nvim_native.keymaps').setup({ auto_select = true })
vim.o.completeopt = 'menuone,noselect,fuzzy'
_G.FuzzySelectionComplete = function(findstart)
    if findstart == 1 then return 0 end
    -- Deliberately return the weaker match first, as an LSP may do.
    return { 'BOOK_TOKENS', '_tokens_rate' }
end
vim.o.completefunc = 'v:lua.FuzzySelectionComplete'
vim.o.complete = 'F'
vim.o.autocomplete = true
local function send(keys) vim.api.nvim_feedkeys(vim.keycode(keys), 't', false) end
local function selected(word, typed)
    local info = vim.fn.complete_info({ 'selected', 'completed', 'items', 'matches' })
    assert(info.selected >= 0, 'missing selection')
    assert(info.completed.word == word, 'wrong selection: ' .. vim.inspect(info))
    assert(vim.api.nvim_get_current_line() == typed, 'selection inserted text')
    assert(info.items[info.selected + 1].match, 'selected item is hidden')
end
local steps = {
    function() selected('_tokens_rate', '_token'); send('<CR><Esc>') end,
    function()
        assert(vim.api.nvim_get_current_line() == '_tokens_rate', 'wrong initial acceptance')
        vim.cmd.enew({ bang = true }); send('i_token')
    end,
    -- Select the weaker match before typing enough to remove it.
    function() selected('_tokens_rate', '_token'); send('<Down>') end,
    function() selected('BOOK_TOKENS', '_token'); send('s_r') end,
    function() selected('_tokens_rate', '_tokens_r'); send('<CR><Esc>') end,
    function()
        assert(vim.api.nvim_get_current_line() == '_tokens_rate', 'accepted filtered-out candidate')
        vim.cmd.enew({ bang = true }); send('i_tokens_rate')
    end,
    function() selected('_tokens_rate', '_tokens_rate'); send('<CR><Esc>') end,
    function()
        assert(vim.api.nvim_get_current_line() == '_tokens_rate', 'exact symbol replaced by unrelated candidate')
        vim.cmd.enew({ bang = true }); send('i_tokens_rate')
    end,
    function() selected('_tokens_rate', '_tokens_rate'); send('<BS>') end,
    function() selected('_tokens_rate', '_tokens_rat'); send('<CR><Esc>') end,
    function()
        assert(vim.api.nvim_get_current_line() == '_tokens_rate', 'backspace acceptance regressed')
        vim.cmd.enew({ bang = true }); send('i_token')
    end,
    function() selected('_tokens_rate', '_token'); send('<Down>') end,
    function() selected('BOOK_TOKENS', '_token'); send('<CR><Esc>') end,
    function()
        assert(vim.api.nvim_get_current_line() == 'BOOK_TOKENS', 'manual selection was overridden')
        print('PASS fuzzy ranking, non-inserting highlight, hidden selection repair, exact-symbol acceptance')
        vim.cmd.qa({ bang = true })
    end,
}
local index = 0
local function step()
    index = index + 1
    if not steps[index] then return end
    local ok, err = pcall(steps[index])
    if not ok then print('step ' .. index .. ': ' .. err); vim.cmd.cquit(); return end
    vim.defer_fn(step, 80)
end
vim.defer_fn(step, 100)
vim.api.nvim_feedkeys('i_token', 'xt!', false)
