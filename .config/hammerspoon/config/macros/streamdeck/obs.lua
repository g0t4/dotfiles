local http_websocket = require("http.websocket")
local json = require("dkjson")

local function connect_to_obs()
    local ws, err = http_websocket.new_from_uri("ws://localhost:4455")
    if not ws then
        print("Failed to connect:", err)
        return nil
    end

    local success, err = ws:connect()
    if not success then
        print("WebSocket connection error:", err)
        return nil
    end

    print("Connected to OBS WebSocket")
    return ws
end

local function get_scene_list()
    local ws = connect_to_obs()
    if not ws then return end

    local request = {
        op = 6,  -- OBS WebSocket Request type
        d = {
            requestType = "GetSceneList",
            requestId = "1234"
        }
    }

    ws:send(json.encode(request))

    local response = ws:receive()
    if response then
        local decoded_response = json.decode(response)
        print("Received Scene List:", json.encode(decoded_response, { indent = true }))
    else
        print("No response received")
    end

    ws:close()
end

get_scene_list()

