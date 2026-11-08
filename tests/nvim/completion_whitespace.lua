-- nvim --clean --headless '+luafile tests/nvim/completion_whitespace.lua'
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/.config/nvim')
local source = require('plugins.completions.nvim_native.sources')
local calls = 0
vim.lsp.omnifunc = function()
    calls = calls + 1
    return -2
end
-- Match the cursor position seen by completion in Insert mode, including EOL.
vim.o.virtualedit = 'onemore'
for _, line in ipairs({ '', ' ', '\t', '    ', 'word ', 'word\t' }) do
    vim.api.nvim_set_current_line(line)
    vim.api.nvim_win_set_cursor(0, { 1, #line })
    assert(source.omnifunc(1, '') == -2)
    assert(vim.deep_equal(source.omnifunc(0, ''), {}))
end
assert(calls == 0, 'whitespace requested LSP completions')
for _, line in ipairs({ 'a', '    a', 'object.' }) do
    vim.api.nvim_set_current_line(line)
    vim.api.nvim_win_set_cursor(0, { 1, #line })
    source.omnifunc(1, '')
end
assert(calls == 3, 'word or punctuation completion was blocked')
print('PASS whitespace suppression and word/member completion delegation')
vim.cmd.qa({ bang = true })
