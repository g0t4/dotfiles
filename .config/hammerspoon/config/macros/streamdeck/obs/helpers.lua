local json = require("dkjson")

function printJson(message, table)
    print(message, json.encode(table, { indent = true }))
end

function errorUnexpectedResponse(response)
    if not response then
        error("Received no response")
    end
    error("Received unexpected response: " .. json.encode(response, { indent = true }))
end

---Wrapper around ws:receive to provide types and split second arg intelligently for consumers
---@param ws table
---@param timeout integer|nil # in SECONDS (see https://daurnimator.github.io/lua-http/0.4/#timeouts)
---@return string|nil textFrame, binary|nil binaryFrame, string|nil error, integer|nil errorCode
function ws_receive(ws, timeout)
    -- TODO does timeout default to infinite?
    -- TODO can I wrap in coroutine and not need to worry about timeout?
    --    https://daurnimator.github.io/lua-http/0.4/#asynchronous-operation
    --    mentions non-blocking in cqueue or compatible container (IIAC coroutine?)
    --    or does this not apply to ws:receive?
    -- TODO cqueues:  https://25thandclement.com/~william/projects/cqueues.html
    --   ok yup, uses yielding coroutines to communicate w/ event controller

    local frame, errorOrFrameType, errorCode = ws:receive(timeout)
    if errorCode == 60 then
        -- FYI consumer must handle timeout, i.e. in case of waiting for events, it's not an error
        --   whereas with authentcation, it likely is
        return nil, nil, nil, errorCode
    elseif errorCode == 1001 then
        -- happens on OBS terminate
        -- TODO is there a lookup of error code explanations somewhere?
        --   Possibly related to http2 protocol?
        return nil, nil, nil, errorCode
    end
    if errorCode then
        return nil, nil, errorOrFrameType, errorCode
    end
    -- errorOrFrame holds a type string
    if errorOrFrameType == "text" then
        return frame
    end
    -- PRN what is the type on a binary frame? find example of this and test it?
    return nil, frame
end

function receiveDecoded(ws)
    -- PRN pass timeout? to receive?

    -- The opcode 0x1 will be returned as "text" and 0x2 will be returned as "binary".
    local textFrame, binaryFrame, err, errorCode = ws_receive(ws)
    if err then
        local message = "error receiving frame: " .. err
        if errorCode then
            message = message .. ", errorCode: " .. errorCode
        end
        error(message)
    end
    if binaryFrame then
        error("unexpected binary frame, was expecting a text frame")
    end
    if textFrame then
        return json.decode(textFrame)
    end
    return nil
end
