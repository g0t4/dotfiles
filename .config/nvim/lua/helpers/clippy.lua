local M = {}

-- simple copy/paste API that centralizes using +/* (or even just ")
--  for when I need to alter how copy paste works, and/or provide new keymaps to use it
--  so consumer code isn't determining this
--  AND so I can fix it in one spot if I have mistakes!

local function get_clipboard_register()
    return vim.o.clipboard:match('unnamedplus') and '+' or '*'
end

function M.set_clipboard(text)
    vim.fn.setreg(get_clipboard_register(), text)
end

function M.get_clipboard()
    return vim.fn.getreg(get_clipboard_register())
end

return M
