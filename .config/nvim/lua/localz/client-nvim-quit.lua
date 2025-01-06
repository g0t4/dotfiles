-- local uv = vim.loop
local uv = require("luv")

local socket_path = "/tmp/iterm2_daemon.sock"

local function send_message()
    local session_id = os.getenv("ITERM_SESSION_ID")
    print("session_id: " .. session_id)
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

send_message()
