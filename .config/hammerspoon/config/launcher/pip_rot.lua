local M = {}
local tasks = {}

function M.reveal(paths)
    local project = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/tools/pip-rot"
    local args = { "run", "--project", project, "--", "python", project .. "/pip_rot.py", "--reveal", "--" }
    for _, path in ipairs(paths) do
        table.insert(args, path)
    end
    -- hs.task bypasses shell expansion, including for unusual filenames.
    local task
    task = hs.task.new("/opt/homebrew/bin/uv", function(code, _, stderr)
        tasks[task] = nil
        if code ~= 0 then
            hs.printf("Pip Rot exited %d: %s", code, stderr or "")
            hs.alert.show("Pip Rot could not open; see Hammerspoon console")
        end
    end, args)
    if task then
        tasks[task] = true
        if not task:start() then
            tasks[task] = nil
            hs.alert.show("Could not start Pip Rot")
        end
    end
end

return M
