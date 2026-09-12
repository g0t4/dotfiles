local os = require("os")
local uv = require("luv")
-- ? does it matter if I use luv or vim.uv?
local log = require('devtools.logs.logger').universal()

local socket_path = os.getenv("HOME") .. "/.config/wes-iterm2/run/semantic-click-handler.sock"
local notify_timeout_ms = 500

local M = {}

function M.NotifyDaemonOfSessionQuit()
    local session_id = os.getenv("ITERM_SESSION_ID")

    if session_id == nil then
        log:warn("[semantic-client] No session id, aborting...")
        return
    end

    local done_or_failed = false
    local client = uv.new_pipe(false)

    local function finish(err)
        if done_or_failed then
            return
        end
        done_or_failed = true
        if err ~= nil then
            log:error("[semantic-client]", err)
        end
        if client ~= nil then
            client:read_stop()
            client:close()
        end
    end

    log:info("[semantic-client] notifying server of quit")

    client:connect(socket_path, function(err)
        if err then
            finish("Error connecting to socket: " .. err)
            return
        end

        log:info("Connected to socket")
        client:write(session_id, function(write_err)
            log:info("[semantic-client] Wrote session_id", session_id)
            if write_err then
                finish("[semantic-client] Error writing to socket: " .. write_err)
                return
            end
            print("Wrote session_id: " .. session_id)

            -- TODO oh yeah derp... I need a response from the server else I start closing the window before it is done getting frame info (hence that error)
            -- FYI could have server send back messages... but let's just go with iterm2's console logs (for daemon)
            client:read_start(function(read_err, data)
                log:info("[semantic-client] Received data: ", data)
                if read_err then
                    finish("[semantic-client] Error reading from socket: " .. read_err)
                    return
                end

                if data == nil then
                    -- EOF without DONE should still unblock shutdown.
                    finish()
                    return
                end

                if data == "DONE" then
                    -- PRN any scenario where all of DONE isn't immediately received in one go?
                    -- IOTW accumulate a buffer across read callbacks
                    finish()
                end
            end)
        end)
    end)

    -- PRN switch to a synchronous socket library (luarocks install luasocket?)... no reason for the client to be async

    local timed_out = not vim.wait(notify_timeout_ms, function()
        -- check if complete (done or fail)
        return done_or_failed
    end, 10)

    if timed_out then
        finish("Timed out waiting for semantic daemon response")
    end
end

return M
