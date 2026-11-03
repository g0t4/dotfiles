local M = {}
local tasks = {}
local log = require("config.logs").hammerspoons()

local function launch(paths, reveal)
    local project = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/tools/pip-rot"
    local args = { "run", "--project", project, "--", "python", project .. "/pip_rot.py" }
    if reveal then table.insert(args, "--reveal") end
    table.insert(args, "--")
    for _, path in ipairs(paths) do
        table.insert(args, path)
    end
    -- hs.task bypasses shell expansion, including for unusual filenames.
    log:info("Launching Pip Rot:", args)
    local task
    task = hs.task.new("/opt/homebrew/bin/uv", function(code, _, stderr)
        tasks[task] = nil
        if code ~= 0 then
            log:error("Pip Rot exited:", code, stderr or "")
            hs.alert.show("Pip Rot could not open; see Hammerspoon console")
        end
    end, args)
    if task then
        tasks[task] = true
        if not task:start() then
            log:error("Could not start Pip Rot task")
            tasks[task] = nil
            hs.alert.show("Could not start Pip Rot")
        end
    end
end

function M.reveal(paths)
    launch(paths, true)
end

function M.open(path)
    launch({path or os.getenv("HOME")}, false)
end

return M
