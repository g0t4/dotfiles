local security = require("config.ask.security")

local M = {}

local filePath = os.getenv("HOME") .. "/.local/share/ask/service"

function M.logSafeService(service)
    -- DO NOT LOG API KEY, log the rest:
    local tmp = {}
    for key, value in pairs(service) do
        if key ~= "api_key" then
            tmp[key] = value
        end
    end
    return tmp
end

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

    if stored.service == "--ollama" then
        return {
            name = "ollama",
            api_key = "whatever",
            base_url = "http://localhost:11434/v1/chat/completions",
            model = stored.model == "" and "llama3.2:3b" or stored.model,
        }
    end

    if stored.service == "--groq" then
        -- TODO any newer models?
        return {
            name = "groq",
            api_key = security.getSecret("ask", "groq"),
            base_url = "https://api.groq.com/openai/v1/chat/completions",
            model = stored.model == "" and "llama-3.1-70b-versatile" or stored.model,
        }
    end

    return {
        name = "openai",
        model = stored.model == "" and "gpt-4o" or stored.model,
        api_key = security.getSecret("ask", "openai"),
        base_url = "https://api.openai.com/v1/chat/completions",
    }
end

return M
