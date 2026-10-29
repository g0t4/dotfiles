local log = require('devtools.logs.logger').universal()
local lua_traces = require("devtools.traces.lua_traces")
local quickfix = require("devtools.traces.quickfix")

-- <leader>h - keys for hammerspoon too...
-- <leader>hf =>
function open_hammerspoon_failure_in_quickfix()
    local fails = require("devtools.logs.fails")
    local task = require("plenary.job")
    vim.notify("finish calling hs")
    -- TODO review/cleanup this triggering of hammerspoon + make it reusable if beneficial elsewhere
    -- TODO! plug in the trace fixer for this too using hs root dirs (see below)
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

function set_quickfix_from_clipboard_IIRC_HAMMERSPOON(reg)
    -- TODO move to devtools.nvim... then update callers too?
    -- TODO was this error format for hammerspoon?
    -- ?? there has to be builtin ways for this already?
    reg = reg or "+"
    local text = vim.fn.getreg(reg)
    text = lua_traces.fix_paths_in_error(text)
    local lines = vim.split(text, "\n")

    vim.fn.setqflist({}, " ", {
        lines = lines,
        efm = [[%A  File "%f"\, line %l\, in %m,%Z%m]],
    })
    vim.cmd("copen")
end

-- `q` as in [q]uickfix
-- TODO move this somewhere else too, was gonna use <leader>h and hence put here but I want <leader>q now
vim.keymap.set('n', "<leader>qhs", open_hammerspoon_failure_in_quickfix)

-- FYI in treesitter you can open in quick fix with ctrl-q and then use these for navigating items:
-- quickfix item navigation:
--  TODO remove these when I am switched over the <leader>c prefixed versions:
vim.keymap.set('n', "<leader>qn", function() vim.print("USE <leader>cn") end) -- next item in quickfix
vim.keymap.set('n', "<leader>qp", function() vim.print("USE <leader>cp") end) -- prev item in quickfix

vim.keymap.set('n', "<leader>qc", quickfix.set_quickfix_from_clipboard)

-- TODO last failure => AskAgent :)
