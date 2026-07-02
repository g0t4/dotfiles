local log = require("config.logs").hammerspoons()

local M = {}

function M.sentence_case(original_text)
    local preserve_words = {
        "GNU", "PROMPT_COMMAND", "PIPESTATUS", "IFS", "PATH", "STDERR", "STDOUT",
        "STDIN", "TTY", "PTY", "PID", "PPID", "UID", "GID", "ANSI", "EOF", "EOL",
        "shopt", "sed", "awk", "wget", "vim", "nvim", "jq",
        "grok.com", "x.com", "PDF", "CSV", "eBay", "xAI", "DeepSearch", "DeeperSearch",
        "vLLM", "FastAPI", "StreamingResponse", "WebSocket", "WebSockets", "HTTPX",
        "ASGI", "WSGI", "GZipMiddleware", "SlowAPIMiddleware", "SlowApi",
        "HorizontalPodAutoscaler", "HPA", "CPU", "GitRepo", "K3s", "RKE2", "RKE", "RKE1",
        "GCP", "GKE", "YAML", "ChatGPT", "K8s", "GPU", "MCP", "ModelContextProtocol",
        "LLM", "LLMs", "AI", "HTTPS", "GH", "PAT",
        "StatefulSet", "DaemonSet", "CronJob", "ReplicaSet",
        "NodePort", "LoadBalancer", "ClusterIP",
        "PersistentVolume", "PersistentVolumeClaim", "StorageClass",
        "ConfigMap", "HostPath", "JDK", "DSL", "systemd", "dockerd", "containerd",
        "ctr", "runc", "k3s", "kubectl", "kubeadm", "PackageReference", "dotnet",
        "CLI", "aspnetcore", "SDK", "dockerignore", "WSL2", "WSL", "VirtualBox", "vagrant",
        "gitignore", "Dockerfile", "docker-compose", "docker-compose.yml", "compose.yml",
        "package.json", "git", "gRPC", "xDS", "Valkey", "valkey", "Redis", "redis", "VM", "VMs", "DNS",
        "/etc/resolv.conf", "dig", "HCL", "SMTP", "SIGHUP", "SIGKILL", "SIGINT", "SIGTERM",
        "MailHog", "VSCode", "SRV", "curl", "consul-template", "envconsul",
        "localhost", "tcpflow", "tcpdump", "ipconfig", "ifconfig", "NGINX",
        ".editorconfig", "EditorConfig", "Vagrantfile",
        "LF", "CRLF", "CR",
        ".gitconfig", ".gitignore", ".gitattributes", ".bash_history", ".zsh_history",
        ".hush_login", ".zshenv", ".zshrc", ".bashrc", ".bash_logout", ".profile",
        ".vscode", ".vagrant.d", ".vagrant", ".ssh", ".config",
        "bash_history",
    }

    -- convert table array to dict for easy lookup
    local perserved_dict = {}
    for _, w in ipairs(preserve_words) do
        perserved_dict[w] = true
    end

    local function to_sentence_case(text)
        return (text:gsub("([^.!?]+)([.!?]?)", function(sentence, punct)
            log:info("sentence", sentence, "punct", punct)

            -- within a sentence... split on whitespace and then:
            -- Each word:
            --   - if exact match in preserve_words then leave as-is
            --   - else if all uppercase letters then leave as-is (assume acronym)
            --   - else if first word => uppercase
            --   - else if not first word => lowercase
            --
            --   - TODO decide if preserve CamelCase too? (do not do this yet)
            --
            local words = {}
            for word, sep in sentence:gmatch("([^%s]+)(%s*)") do
                log:info("word", vim.inspect(word))
                local is_acronym = word:match("^%u+$") and #word > 1
                if perserved_dict[word] or is_acronym then
                    -- keep word as-is
                else
                    if #words == 0 then
                        word = word:sub(1, 1):upper() .. word:sub(2):lower()
                    else
                        word = word:sub(1, 1):lower() .. word:sub(2)
                    end
                end
                table.insert(words, word .. sep)
            end
            sentence = table.concat(words)
            return sentence .. punct
        end))
    end

    return to_sentence_case(original_text)
end

function M.transform_selection_via_clipboard(operation)
    local original_clipboard_text = hs.pasteboard.readString() or "" -- FYI not handling case where pasteboard is not text which I could theoretically handle but MEH

    -- * copy selection
    hs.eventtap.keyStroke({ 'cmd' }, 'c')
    local selected_text = hs.pasteboard.readString() or ""

    local new_text = operation(selected_text)

    -- * paste it over selection
    hs.pasteboard.writeObjects({ new_text })
    hs.eventtap.keyStroke({ 'cmd' }, 'v')

    -- * restore clipboard
    hs.pasteboard.setContents(original_clipboard_text)
end

return M
