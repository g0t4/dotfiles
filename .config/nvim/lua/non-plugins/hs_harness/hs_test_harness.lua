local log = require("devtools.logs.logger").universal()
local Path = require "plenary.path"
local Job = require "plenary.job"

-- FYI use hs CLI to run outside of nvim => thus no need for `headless` mode (unlike plenary nvim unit tests)

local plenary_dir = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"

local harness = {
    HIDE_FLOAT_WINDOW = true
}

function harness.test_directory_command(command)
    local split_string = vim.split(command, " ")
    local directory = vim.fn.expand(table.remove(split_string, 1))

    local opts = assert(loadstring("return " .. table.concat(split_string, " ")))()

    return harness.test_directory(directory, opts)
end

local function test_paths(paths, opts)
    opts = vim.tbl_deep_extend("force", {
        nvim_cmd = "/opt/homebrew/bin/hs",
        winopts = { winblend = 3 },
        sequential = false,
        keep_going = true,
        timeout = 50000,
    }, opts or {})

    vim.env.PLENARY_TEST_TIMEOUT = opts.timeout

    local path_len = #paths
    local failure = false

    local jobs = vim.tbl_map(function(p)
        local args = {}

        -- TODO? run plenary.busted style tests instead of just code file?
        -- FYI get this working in a test file first, easier to type out there and then migrate to -c arg here
        --  TODO or have some code file that you pass to hs too that prepares env before test file is run?
        -- table.insert(args, "-c")
        -- "set rtp+=.," .. vim.fn.escape(plenary_dir, " ") .. " | runtime plugin/plenary.vim",
        -- table.insert(args, "-c")
        -- table.insert(args, string.format('lua require("plenary.busted").run("%s")', p:absolute():gsub("\\", "\\\\")))

        -- * just execute lua code (not unit test style yet) *
        -- hammerspoon accepts lua files to execute too:
        table.insert(args, p:absolute())
        -- table.insert(args,  p.filename)

        -- log:info("hs args", args)
        local job = Job:new {
            command = opts.nvim_cmd,
            args = args,

            -- Can be turned on to debug
            on_stdout = function(_, data)
                if path_len == 1 and data ~= nil then
                    -- redirect to log
                    log:info(data)
                end
            end,

            on_stderr = function(_, data)
                if path_len == 1 and data ~= nil then
                    -- redirect to log
                    log:info(data)
                end
            end,

            on_exit = vim.schedule_wrap(function(j_self, _, _)
                if path_len ~= 1 then
                    log:info(unpack(j_self:stderr_result()))
                    log:info(unpack(j_self:result()))
                end
            end),
        }
        job.nvim_busted_path = p.filename
        return job
    end, paths)

    -- log:info "Running hammerspoon test/script harness..."
    for i, j in ipairs(jobs) do
        log:info("Running: " .. j.nvim_busted_path)
        j:start()
        if opts.sequential then
            log:debug("... Sequential wait for job number", i)
            if not Job.join(j, opts.timeout) then
                log:debug("... Timed out job number", i)
                failure = true
                pcall(function()
                    j.handle:kill(15) -- SIGTERM
                end)
            else
                log:debug("... Completed job number", i, j.code, j.signal)
                failure = failure or j.code ~= 0 or j.signal ~= 0
            end
            if failure and not opts.keep_going then
                break
            end
        end
    end
end

function harness.test_directory(directory, opts)
    print "Starting..."
    directory = directory:gsub("\\", "/")
    local paths = harness._find_files_to_run(directory)

    -- Paths work strangely on Windows, so lets have abs paths
    if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
        paths = vim.tbl_map(function(p)
            return Path:new(directory, p.filename)
        end, paths)
    end

    test_paths(paths, opts)
end

function harness.test_file(filepath)
    test_paths { Path:new(filepath) }
end

function harness._find_files_to_run(directory)
    local finder
    if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
        -- On windows use powershell Get-ChildItem instead
        local cmd = vim.fn.executable "pwsh.exe" == 1 and "pwsh" or "powershell"
        finder = Job:new {
            command = cmd,
            args = { "-NoProfile", "-Command", [[Get-ChildItem -Recurse -n -Filter "*_spec.lua"]] },
            cwd = directory,
        }
    else
        -- everywhere else use find
        finder = Job:new {
            command = "find",
            args = { directory, "-type", "f", "-name", "*_spec.lua" },
        }
    end

    return vim.tbl_map(Path.new, finder:sync(vim.env.PLENARY_TEST_TIMEOUT))
end

function harness._run_path(test_type, directory)
    local paths = harness._find_files_to_run(directory)

    local bufnr = 0
    local win_id = 0

    for _, p in pairs(paths) do
        print " "
        log:info("Loading Tests For: ", p:absolute(), "\n")

        local ok, result = pcall(function()
            dofile(p:absolute())
        end)

        if not ok then
            log:error("Failed to load file", result)
        end
    end

    harness:run(test_type, bufnr, win_id)

    return paths
end

function run_hammerspoon_tests()
    local current_file = vim.fn.expand('%:p')
    test_paths({ Path:new(current_file) })
end

function harness.setup()
    vim.keymap.set('n', "<leader>hs", run_hammerspoon_tests)
end

return harness
