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
    -- trim new lines if any
    service = service:gsub("\n", "")
    model = model:gsub("\n", "")
    return { service = service, model = model }
end

function M.getService()
    local stored = M.getStoredService()
    -- print("stored", hs.inspect(stored))
    if stored == nil then
        return nil
    end

    if stored.service == "--ollama" then
        return {
            name = "ollama",
            api_key = "whatever",
            url = "http://ollama:11434/v1/chat/completions",
            model = stored.model == "" and "llama3.2:3b" or stored.model,
        }
    end

    if stored.service == "--inception" then
        return {
            name = "inception",
            api_key = security.getSecret("ask", "inception"),
            url = "https://api.inceptionlabs.ai/v1/chat/completions",
            model = stored.model == "" and "mercury-coder-small" or stored.model,
        }
    end

    if stored.service == "--groq" then
        return {
            name = "groq",
            api_key = security.getSecret("ask", "groq"),
            url = "https://api.groq.com/openai/v1/chat/completions",
            model = stored.model == "" and "meta-llama/llama-4-scout-17b-16e-instruct" or stored.model,
        }
    end

    if stored.service == "--xai" then
        return {
            name = "xai",
            api_key = security.getSecret("ask", "xai"),
            url = "https://api.x.ai/v1/chat/completions",
            model = stored.model == "" and "grok-3-beta" or stored.model,
        }
    end

    return {
        name = "openai",
        model = stored.model == "" and "gpt-4o" or stored.model,
        api_key = security.getSecret("ask", "openai"),
        url = "https://api.openai.com/v1/chat/completions",
    }
end

return M
