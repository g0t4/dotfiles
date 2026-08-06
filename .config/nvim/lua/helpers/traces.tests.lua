require("tests.setup").modify_package_path()
local should = require('devtools.tests.should')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')

local traces = require("helpers.traces")

local cwd = vim.fn.getcwd()
print(cwd)

-- local test = cwd .. "/.config/hammerspoon/config/rx/hammerspoon_timeout_scheduler.lua"
-- local test = cwd .. "/.config/nvim/lua/helpers/traces.tests.lua" -- from repo root
local test = cwd .. "/lua/helpers/traces.tests.lua" -- from nvim dir for tests to run
print(test)
print("SHORTENED", traces.lua_short_path(test))

-- make traceback
local function boom()
    error("boom")
end

local ok, err = xpcall(boom, debug.traceback)

print("\n******************** Original traceback:\n")
print(err)

print("\n******************** search:\n")
local fixed = err:gsub("(%.%.%.*[^:\n]+)", function(short_path)
    print("COCKASS", short_path)
    local full = traces.resolve_truncated_path(vim.fn.getcwd(), short_path)
    print("   FULL: ", vim.inspect(full))
    return full or short_path
end)

print("\n ********************* Fixed traceback:\n")
print(fixed)
