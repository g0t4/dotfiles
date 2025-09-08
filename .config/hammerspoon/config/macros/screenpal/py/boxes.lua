local json = require("hs.json")

function runDetection(imagePath, callback)
    local script = "/usr/local/bin/python3"
    local args = { "/path/to/detect_box.py", imagePath }

    local task = hs.task.new(script, function(exitCode, stdout, stderr)
        if exitCode == 0 and stdout then
            local ok, data = pcall(json.decode, stdout)
            if ok then
                callback(data)
            else
                hs.alert.show("JSON decode error: " .. tostring(stdout))
            end
        else
            hs.alert.show("Python error: " .. tostring(stderr))
        end
    end, args)

    task:start()
end

runDetection("/Users/wesdemos/Pictures/Screencaps/timeline03a.png", function(result)
    print("Box center fraction: " .. tostring(result.center_fraction))
end)
