---@param imagePath string
---@param callback fun(data: SilencesList)
function detect_silence_boxes(imagePath, callback, script)
    filename = filename or "boxes.py"
    local python_exe = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.venv/bin/python3"
    local script = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.config/hammerspoon/config/macros/screenpal/py/" .. filename
    local args = { script, imagePath }

    local task = hs.task.new(python_exe, function(exitCode, stdout, stderr)
        if exitCode == 0 and stdout then
            local ok, silences = pcall(hs.json.decode, stdout)
            if ok then
                callback(silences)
            else
                print("JSON decode error: " .. tostring(stdout))
            end
        else
            print("Python error: " .. tostring(stderr))
        end
    end, args)

    task:start()
end

function detect_short_silences(imagePath, callback, script)
    detect_silence_boxes(imagePath, callback, "dark-boxes.py")
end
