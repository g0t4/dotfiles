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


    local function log_file(msg)
        -- disable for now, can re-enable if needed
        if true then
            return
        end

        local path = os.getenv("HOME") .. "/.config/wes-iterm2/semantic-client.log"
        local file = io.open(path, "a")
        if not file then
            print("Error opening log file: " .. path)
            return
        end
        file:write(msg .. "\n")
        file:close()
    end

    log_file("Starting client...")

    local done_or_failed = false

    client:connect(socket_path, function(err)
        log_file("Connected to socket...")
        client:write(session_id, function(write_err)
            log_file("Wrote session_id: " .. session_id)
            if write_err then
                log_file("Error writing to socket: " .. write_err)
                print("Error writing to socket: " .. write_err)
                done_or_failed = true
                client:close()
                uv.stop()
                return
            end
            print("Wrote session_id: " .. session_id)

            -- TODO oh yeah derp... I need a response from the server else I start closing the window before it is done getting frame info (hence that error)
            -- FYI could have server send back messages... but let's just go with iterm2's console logs (for daemon)
            client:read_start(function(read_err, data)
                log_file("Received data: " .. data)
                if read_err then
                    print("Error reading from socket: " .. read_err)
                    done_or_failed = true
                    client:close()
                    uv.stop()
                    return
                end

                if data == "DONE" then
                    -- PRN any scenario where all of DONE isn't immediately received in one go? IOTW accumulate a buffer across read callbacks
                    done_or_failed = true
                    client:close()
                    uv.stop()
                end
            end)
        end)
    end)

    -- PRN switch to a synchronous socket library (luarocks install luasocket?)... no reason for the client to be async
    -- TODO how about add a timeout to bail if it takes too long?... i.e. if server never responds w/ message
    while not done_or_failed do
        -- FYI, first call to uv.run() returns after client:write and before client:read_start is called... so I have to call it again
        -- so, use a boolean now to check if done and loop on uv.run()... works good
        -- FYI also uv.sleep(10) fixes the race condition too...
        -- basically once this exits my callbacks are doomed b/c the iterm window is nuked before the server is done gathering window state
        uv.run("default")
    end
end

return M
