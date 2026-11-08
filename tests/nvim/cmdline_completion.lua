-- nvim --clean --headless '+luafile tests/nvim/cmdline_completion.lua'
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/.config/nvim')
for _, name in ipairs({ 'nvim-cmp', 'cmp-buffer', 'cmp-path', 'cmp-cmdline' }) do
    vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/' .. name)
end
local cmp = require('cmp')
for name, module in pairs({ buffer = 'cmp_buffer.source', path = 'cmp_path', cmdline = 'cmp_cmdline' }) do
    cmp.register_source(name, require(module).new())
end
cmp.setup({ enabled = function() return vim.fn.getcmdtype() ~= '' end })
require('plugins.completions.nvim_cmp.cmdline').setup()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'alpha alphabet alpine beta gamma delta' })
local function send(keys) vim.api.nvim_feedkeys(vim.keycode(keys), 't', false) end
local function menu(prefix)
    assert(cmp.visible(), 'missing menu for ' .. prefix)
    local entries = cmp.get_entries()
    assert(#entries > 0, 'empty menu')
    for _, entry in ipairs(entries) do
        assert(entry.completion_item.label:sub(1, #prefix) == prefix,
            'unrelated candidate for ' .. prefix .. ': ' .. entry.completion_item.label)
    end
end
local function closed() assert(not cmp.visible(), 'stale/unwanted completion menu') end
local steps = {
    function() send('/') end,
    function() send('alph') end,
    function() menu('alph'); send('<BS>') end,
    function() menu('alp'); send(' ') end,
    function() closed(); send('bet') end,
    function() menu('bet'); send('<C-w>') end,
    function() closed(); assert(vim.fn.getcmdline() == 'alp '); send('<BS>') end,
    function() menu('alp'); send('<Left>') end,
    function() closed(); assert(vim.fn.getcmdpos() == 3); send('<BS>') end,
    function() menu('a'); assert(vim.fn.getcmdline() == 'ap'); send('<Right>') end,
    function() closed(); send('<End>') end,
    function() closed(); send('<C-w>') end,
    function() closed(); assert(vim.fn.getcmdline() == ''); send('<Tab>') end,
    function() assert(cmp.visible(), 'explicit Tab completion lost'); send('<Esc>') end,
    function() send('?') end,
    function() send('bet') end,
    function() menu('bet'); send('<Left>') end,
    function() closed(); send('<Esc>') end,
    function() send(':') end,
    function() send('set nu') end,
    function() assert(cmp.visible(), 'missing Ex completion'); send('<C-w>') end,
    function() closed(); assert(vim.fn.getcmdline() == 'set '); send('<Tab>') end,
    function() assert(cmp.visible(), 'explicit Ex argument completion lost'); send('<Left>') end,
    function() closed(); send('<Esc>') end,
    function()
        print('PASS command-line deletion, whitespace, cursor movement, search and Ex, explicit Tab')
        vim.cmd.qa({ bang = true })
    end,
}
local index = 0
local function step()
    index = index + 1
    if not steps[index] then return end
    local ok, err = pcall(steps[index])
    if not ok then print('step ' .. index .. ': ' .. err); vim.cmd.cquit(); return end
    vim.defer_fn(step, 200)
end
vim.defer_fn(step, 20)
