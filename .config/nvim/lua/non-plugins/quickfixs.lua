local log = require("devtools.logs.logger").universal()

-- <leader>h - keys for hammerspoon too...
-- <leader>hf =>
function open_hammerspoon_failure_in_quickfix()
    local fails = require("devtools.logs.fails")
    local task = require("plenary.job")
    vim.notify("finish calling hs")
    -- TODO review/cleanup this triggering of hammerspoon + make it reusable if beneficial elsewhere
    task:new({
        command = "hs",
        args = { "-c", "StreamDeckKeyboardMaestroRunner('HS_last_failure_to_nvim_quickfix()')" },
        on_stdout = function(_, data)
            if data then
                log:info("hs -c on_stdout", data)
            end
        end,
        -- on_stderr?  TODO stderr
        on_exit = function(_, code, _)
            -- TODO log anything else? log nothing?
            log:info("hs -c on_exit (code=" .. code .. ")")
        end,
    }):start()
end

-- `q` as in [q]uickfix
-- TODO move this somewhere else too, was gonna use <leader>h and hence put here but I want <leader>q now
vim.keymap.set('n', "<leader>qhs", open_hammerspoon_failure_in_quickfix)

-- FYI in treesitter you can open in quick fix with ctrl-q and then use these for navigating items:
-- quickfix item navigation:
vim.keymap.set('n', "<leader>qn", function() vim.cmd('cnext') end) -- next item in quickfix
vim.keymap.set('n', "<leader>qp", function() vim.cmd('cprev') end) -- prev item in quickfix
-- move by file:
vim.keymap.set('n', "<leader>qnf", function() vim.cmd('cnfile') end)
vim.keymap.set('n', "<leader>qpf", function() vim.cmd('cpfile') end)

vim.keymap.set('n', "<leader>qp", function() vim.cmd('cprev') end) -- prev item in quickfix
-- vim.keymap.set('n', "<leader>qc", function() end) -- TODO open clipboard in quickfix (already done with hs quickfix approach (move part back here to nvim))


-- TODO last failure => AskAgent :)
