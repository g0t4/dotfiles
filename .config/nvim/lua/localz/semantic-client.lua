local os = require("os")
-- local uv = vim.loop
local uv = require("luv")
-- ? does it matter if I use luv or vim.loop?

local socket_path = os.getenv("HOME") .. "/.config/wes-iterm2/run/semantic-click-handler.sock"

local M = {}

function M.NotifyDaemonOfSessionQuit()
    local session_id = os.getenv("ITERM_SESSION_ID")

    if session_id == nil then
        print("No session id, aborting...")
        return
    end

    local client = uv.new_pipe(false)


    client:connect(socket_path, function(err)
        client:write(session_id, function(write_err)
            if write_err then
                print("Error writing to socket: " .. write_err)
                return
            end

            client:close()

            -- FYI could have server send back messages... but let's just go with iterm2's console logs (for daemon)
            -- client:read_start(function(read_err, data)
            -- end)
            uv.stop()
        end)
    end)
    uv.run("default")
end

return M
