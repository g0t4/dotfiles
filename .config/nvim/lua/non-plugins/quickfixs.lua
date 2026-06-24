-- <leader>h - keys for hammerspoon too...
-- <leader>hf =>
function open_hammerspoon_failure_in_quickfix()
    local fails = require("devtools.logs.fails")
    local task = require("plenary.job")
    vim.notify("finish calling hs")
    -- TODO hs -c "StreamDeckKeyboardMaestroRunner('HS_last_failure_to_nvim_quickfix()')"
end

-- `q` as in [q]uickfix
-- TODO move this somewhere else too, was gonna use <leader>h and hence put here but I want <leader>q now
vim.keymap.set('n', "<leader>qhs", open_hammerspoon_failure_in_quickfix)
vim.keymap.set('n', "<leader>qn", function() end) -- TODO_open_neovim_failure_in_quickfix
vim.keymap.set('n', "<leader>qc", function() end) -- TODO open clipboard in quickfix (already done with hs quickfix approach (move part back here to nvim))


-- TODO last failure => AskAgent :)
