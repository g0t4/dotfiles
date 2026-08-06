require("tests.setup").modify_package_path()
local should = require('devtools.tests.should')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')
local traces = require("helpers.traces")
-- FYI changing lines below may mess up line numbers in assertion below for this file, just shift those for traces.tests.lua and it'll be fine!

local function boom()
    error("boom")
end

describe("resolve_truncated_path", function()
    it("works for test case error", function()
        local ok, err = xpcall(boom, debug.traceback)

        -- print("\n******************** Original traceback:\n")
        -- print(err)

        -- print("\n******************** search:\n")
        local fixed = err:gsub("(%.%.%.*[^:\n]+)", function(short_path)
            -- print("SEARCHING FOR: ", short_path)
            local full = traces.resolve_truncated_path(short_path)
            -- print("   FULL: ", vim.inspect(full))
            return full or short_path
        end)

        -- print("\n ********************* Fixed traceback:\n")
        -- print(fixed)

        local fixed_string = tostring(fixed)

        local home = vim.fn.getenv("HOME")
        local expected = home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:10: boom
stack traceback:
	[C]: in function 'error'
	]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:10: in function <]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:9>
	[C]: in function 'xpcall'
	]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:15: in function <]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:14>
	[C]: in function 'xpcall'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:175: in function 'it'
	]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:14: in function <]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:13>
	[C]: in function 'xpcall'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:120: in function 'original_describe'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/tests/define/describe.lua:16: in function 'describe'
	]] .. home .. [[/repos/github/g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:13: in function 'loaded'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:239: in function <]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:238>]]


        -- .../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:20: boom
        -- stack traceback:
        --         [C]: in function 'error'
        --         .../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:20: in function <.../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:19>
        --         [C]: in function 'xpcall'
        --         .../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:60: in function <.../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:59>
        --         [C]: in function 'xpcall'
        --         ...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
        --         ...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:175: in function 'it'
        --         .../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:59: in function <.../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:58>
        --         [C]: in function 'xpcall'
        --         ...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
        --         ...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:120: in function 'original_describe'
        --         ...0t4/devtools.nvim/lua/devtools/tests/define/describe.lua:16: in function 'describe'
        --         .../g0t4/dotfiles/.config/nvim/lua/helpers/traces.tests.lua:58: in function 'loaded'
        --         ...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:239: in function <...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:238>


        should.be_same_colorful_diff(expected, fixed_string)
    end)
end)
