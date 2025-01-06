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
                client:close()
                uv.stop()
                return
            end

            -- FYI could have server send back messages... but let's just go with iterm2's console logs (for daemon)
            -- client:read_start(function(read_err, data)
            -- end)

            client:close()
            -- w/o this, the loop blocks on uv.run() indefinitely (even though all handles are closed at this point...), so make sure to call uv.stop()
            -- w/o this you can send SIGWINCH and that will trigger loop cleanup (even if client:close() is not called, in my testing... must check state of connection and close it on SIGWINCH too, or?)
            uv.stop()
        end)
    end)
    uv.run("default")
    -- print("notify client is done...") --  use this to troubleshoot event loop hanging
end

return M
