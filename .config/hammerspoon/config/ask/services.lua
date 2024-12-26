local security = require("config.ask.security")

local M = {}

local filePath = os.getenv("HOME") .. "/.local/share/ask/service"

local function readServiceFile()
    local file = io.open(filePath, "r")
    if file then
        local contents = file:read("*all")
        file:close()
        return contents
    end
    print("Error: failed to open", filePath)
    return nil
end

function M.getStoredService()
    -- format of file contents (single line):
    --   --service model
    --
    local contents = readServiceFile()
    if contents == nil then
        print("Error: file appears to be empty", filePath)
        return nil
    end
    -- split on first space
    local service = contents:match("(.-)%s")
    local model = contents:match("%s(.-)$")
    return { service = service, model = model }
end

function M.getService()
    local stored = M.getStoredService()
    if stored == nil then
        return nil
    end

    -- if stored.service == "--groq" then
    --     return { service = "groq", model = "gpt-4o" }
    -- end

    return {
        name = "openai",
        model = stored.model == "" and "gpt-4o" or stored.model,
        api_key = security.getSecret("ask", "openai"),
        base_url = "https://api.openai.com/v1/chat/completions",
    }
end

return M
