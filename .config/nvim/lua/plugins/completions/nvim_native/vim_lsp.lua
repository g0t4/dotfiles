-- Native LSP for source buffers. Command-line completion stays in cmdline_cmp.lua.
vim.opt.completeopt = { "menuone", "noselect", "popup" }
vim.diagnostic.config({
    signs = false,
    virtual_text = false,
    underline = { severity = { min = vim.diagnostic.severity.INFO } },
    severity_sort = true
})
-- vim.lsp.document_color.enable(false)
vim.lsp.inlay_hint.enable(false)
vim.lsp.codelens.enable(false)

-- FYI `:checkhealth vim.lsp` shows language servers and active features per buffer!

-- disable semantic_tokens to avoid adding highlights on top of treesitter highlighting...
--  maybe I can bring this back if it is useful for language server to provide this too...
--  but, the default comment style clashed with my colorful comment styles (i.e. find comment with "FYI") :hi @lsp.type.comment
--  I could just clear the highlight group... but, let's just nuke this for now...
--  TODO any utility in semantic_tokens beyond highlighting? kinda confusing that lsp-semantic-highlights is a separate help section
--    which suggests there are other uses for `:h lsp-semantic-tokens` beyond coloring code?
--    and yet there's no vim.lsp.semantic_highlights.enable(false)
--    so they seem intertwined?
vim.lsp.semantic_tokens.enable(false)

vim.lsp.config("lua", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    workspace_required = false,
    settings = {
        Lua = {
            runtime = { version = "LuaJIT", path = { "?.lua", "?/init.lua" } },
            workspace = { checkThirdParty = false },
            completion = { callSnippet = "Both", keywordSnippet = "Replace" },
            -- Project globals belong in that project's .luarc.json.
        },
    },
})

vim.lsp.config("pyright", {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", ".git" },
    workspace_required = false,
    settings = {
        python = {
            analysis = {
                inlayHints = {
                    variableTypes = false, parameterTypes = false, functionReturnTypes = false,
                }
            }
        },
    },
})

vim.lsp.config("xonsh", {
    -- cmd = { "uv", "tool", "run", "-n", "xonsh-lsp" }, -- also works to explicitly use uv
    cmd = { "xonsh-lsp", "--stdio" },
    filetypes = { "xonsh" },
    root_markers = { ".xonshrc", "xonshrc", ".git" },
    workspace_required = false,
    init_options = { pythonBackend = "pyright" },
})

-- The live config links individual files into this repo, not the whole nvim directory.
local source_file = vim.fn.resolve(debug.getinfo(1, "S").source:sub(2))
local server_bin = vim.fn.fnamemodify(source_file, ":h:h:h:h") .. "/node_modules/.bin/"

vim.lsp.config("typescript", {
    cmd = { server_bin .. "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
    workspace_required = false,
    settings = {
        typescript = { format = { insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true } },
    },
})

vim.lsp.config("docker", {
    cmd = { server_bin .. "docker-langserver", "--stdio" },
    filetypes = { "dockerfile" },
    root_markers = { "Dockerfile", "compose.yaml", "docker-compose.yml", ".git" },
    workspace_required = false,
})

vim.lsp.config("yaml", {
    cmd = { server_bin .. "yaml-language-server", "--stdio" },
    filetypes = { "yaml" }, -- Ansible buffers have their own filetype/server.
    root_markers = { ".yamllint", "package.json", ".git" },
    workspace_required = false,
    settings = {
        yaml = {
            format = { enable = false },
            schemaStore = { enable = true },
            schemas = {
                kubernetes = {
                    "k8s/*.yaml", "k8s/*.yml", "k8s/**/*.yaml", "k8s/**/*.yml",
                    "kubernetes/*.yaml", "kubernetes/*.yml",
                    "kubernetes/**/*.yaml", "kubernetes/**/*.yml",
                }
            },
        },
    },
})

vim.lsp.config("json", {
    cmd = { server_bin .. "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { "package.json", ".git" },
    workspace_required = false,
    settings = {
        json = {
            validate = { enable = false },
            format = { keepLines = true },
            schemas = { {
                fileMatch = { ".luarc.json", ".luarc.jsonc" },
                url = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
            } },
        },
    },
})

vim.lsp.config("bash", {
    cmd = { server_bin .. "bash-language-server", "start" },
    filetypes = { "sh" },
    root_markers = { ".shellcheckrc", ".git" },
    workspace_required = false,
})

vim.lsp.config("ansible", {
    cmd = { "ansible-language-server", "--stdio" },
    filetypes = { "ansible" },
    root_markers = { "ansible.cfg", ".git" },
    workspace_required = false,
    settings = {
        ansible = {
            validation = { enabled = true, lint = { enabled = true } },
            python = { interpreterPath = "python3" },
        },
    },
})

vim.lsp.config("nix", {
    cmd = { "nixd" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", ".git" },
    workspace_required = false,
    settings = { nixd = { formatting = { command = { "nixfmt" } } } },
})

vim.lsp.config("treesitter_query", {
    cmd = { "ts_query_ls" },
    filetypes = { "query" },
    root_markers = { ".tsqueryrc.json", ".git" },
    workspace_required = false,
})

vim.lsp.config("fish", {
    cmd = { "fish-lsp", "start" },
    filetypes = { "fish" },
    root_markers = { "config.fish", ".git" },
    workspace_required = false,
    cmd_env = { fish_lsp_diagnostic_disable_error_codes = "2003 2001" },
    init_options = {
        workspaces = {
            paths = {
                defaults = {
                    vim.fn.expand("~/.config/fish"), "/opt/homebrew/share/fish",
                }
            }
        }
    },
})

local function format_buffer(range)
    if vim.bo.filetype == "yaml" or vim.bo.filetype == "ansible" then
        vim.cmd("normal! gg=G")
    elseif vim.bo.filetype == "xonsh" or vim.bo.filetype == "python" then
        -- Neither xonsh-lsp nor Pyright formats; keep the existing CLI formatters.
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local yapf = vim.fn.exepath("yapf")
        if yapf == "" then
            yapf = vim.fn.expand("~/repos/github/g0t4/dotfiles/.venv/bin/yapf")
        end
        local cmd = vim.bo.filetype == "xonsh" and { "xonsh", "format", "-" } or {
            yapf, "--style",
            "{column_limit: 400, allow_split_before_dict_value: False, join_multiple_lines: False}",
        }
        if range and vim.bo.filetype == "python" then
            vim.list_extend(cmd, { "--lines", string.format("%d-%d", range[1], range[2]) })
        end
        local output = vim.fn.systemlist(cmd, table.concat(lines, "\n") .. "\n")
        if vim.v.shell_error ~= 0 then
            vim.notify(cmd[1] .. " format failed:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR)
            return
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
    else
        vim.lsp.buf.format({ async = true })
    end
end

vim.api.nvim_create_user_command("FormatBuffer", function() format_buffer() end, {})

-- FYI wes checklist when reviewing new config
-- 1. goto jumping works (gd/F12, <leader>gr/F24 for references opens loclist)
-- 2. hover help (shift+K)
-- 3. rename local variable (F2/<leader>rn)
-- 4. diagnostics jumping ]g and [g
-- 5. completions (as I type + on-demand)
-- 6. formatting file/selection (when applicable for language/server)

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("native_lsp_mappings", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end
        if client:supports_method("textDocument/completion") then
            -- 'autocomplete' collects the LSP omnifunc and LuaSnip source in
            -- the same popup. Keep native LSP acceptance and manual requests.
            vim.lsp.completion.enable(true, client.id, args.buf)
        end

        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "LSP definition")
        map("n", "<F12>", vim.lsp.buf.definition, "LSP definition")
        map("n", "gt", vim.lsp.buf.type_definition, "LSP type definition")
        map("n", "gy", vim.lsp.buf.type_definition, "LSP type definition")
        map("n", "<leader>gi", vim.lsp.buf.implementation, "LSP implementation")
        map("n", "<leader>ge", vim.lsp.buf.declaration, "LSP declaration")
        map("n", "<leader>gr", vim.lsp.buf.references, "LSP references")
        map("n", "<F24>", vim.lsp.buf.references, "LSP references")
        map("n", "<leader>gru", function()
            vim.lsp.buf.references({ includeDeclaration = false })
        end, "LSP usages")
        map("n", "K", vim.lsp.buf.hover, "LSP hover")
        map("n", "<leader>rn", vim.lsp.buf.rename, "LSP rename")
        map("n", "<F2>", vim.lsp.buf.rename, "LSP rename")
        map("n", "<leader>co", vim.lsp.buf.document_symbol, "LSP document symbols")
        map("n", "<leader>cs", vim.lsp.buf.workspace_symbol, "LSP workspace symbols")
        map("n", "<leader>cf", ":cfirst<CR>", "First result")
        map("n", "<leader>cl", ":clast<CR>", "Last result")
        map("n", "<leader>cn", ":cnext<CR>", "Next result")
        map("n", "<leader>cp", ":cprevious<CR>", "Previous result")

        map("n", "<leader>cd", function()
            local function client_positional_params(params)
                local win = vim.api.nvim_get_current_win()
                return function(client)
                    local ret = vim.lsp.util.make_position_params(win, client.offset_encoding)
                    if params then
                        ret = vim.tbl_extend('force', ret, params)
                    end
                    return ret
                end
            end

            -- vim.lsp.buf_request_all(0, 'experimental/serverStatus', client_positional_params(), function(results, ctx)
            --     local bufnr = assert(ctx.bufnr)
            --     if vim.api.nvim_get_current_buf() ~= bufnr then
            --         -- Ignore result since buffer changed. This happens for slow language servers.
            --         return
            --     end
            --     -- Filter errors from results
            --     local results1 = {} --- @type table<integer,lsp.Hover>
            --     local log = require("devtools.logs.logger"):universal()
            --     log:info("results", results)
            -- end)

            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics > 0 then
                vim.diagnostic.setloclist({ open = true })
                return
            end

            local log = require("devtools.logs.logger"):universal()
            -- * crude attempt at getting progress

            -- for _, client in ipairs(vim.lsp.get_clients()) do
            --     --- @diagnostic disable-next-line:no-unknown
            --     for progress in client.progress do
            --         --- @cast progress {token: lsp.ProgressToken, value: lsp.LSPAny}
            --         local value = progress.value
            --         if type(value) == 'table' and value.kind then
            --             local message = value.message and (value.title .. ': ' .. value.message) or value.title
            --             messages[#messages + 1] = message
            --             if value.percentage then
            --                 percentage = math.max(percentage or 0, value.percentage)
            --             end
            --         end
            --         -- else: Doesn't look like work done progress and can be in any format
            --         -- Just ignore it as there is no sensible way to display it
            --     end
            -- end

            local message = "No diagnostics\n\nLSP clients doing_something: "
            for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                local last_progress
                -- log:info("client.progress (ring buffer)", c.progress)
                local pending = c.progress.pending -- empty might mean not loading :) ...
                -- FYI lua ls =>  pending = { [1333] = "Diagnosing workspace" },
                --   TODO I could look at "diagnosing workspace" or w/e statuses might be here?
                local doing_something = next(pending) ~= nil
                -- for progress in c.progress do
                --     --     -- log:warn("prog", progress)
                --     last_progress = progress.value
                -- end

                local status = {
                    name = c.name,
                    id = c.id,
                    doing_something = doing_something,
                    initialized = c.initialized,
                    stopped = c:is_stopped(),
                    -- requests = c.requests,
                    -- last_progress = last_progress,
                }
                -- log:info("stat", status)
                if doing_something then
                message = message .. "\n" .. c.name
                end
            end
            vim.lsp.status() --  is terrible (dumps progress message ring buffer per LSP client, useless)
            vim.notify(messag, vim.log.levels.INFO)
        end, "Buffer diagnostics")

        map("n", "[g", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
        map("n", "]g", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map("n", "[e", function()
            vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        end, "Previous error")
        map("n", "]e", function()
            vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        end, "Next error")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP code actions")
        map("x", "<leader>ca", vim.lsp.buf.code_action, "LSP code actions for selection")
        map("n", "<leader>cal", function()
            local row = vim.api.nvim_win_get_cursor(0)[1]
            vim.lsp.buf.code_action({
                range = {
                    start = { row, 0 }, ["end"] = { row, #vim.api.nvim_get_current_line() },
                }
            })
        end, "LSP line actions")
        map("n", "<leader>cqf", function()
            vim.lsp.buf.code_action({ context = { only = { "quickfix" } }, apply = true })
        end, "LSP quick fix")
        map("n", "<leader>cas", function()
            vim.lsp.buf.code_action({ context = { only = { "source" } } })
        end, "LSP source actions")
        map({ "n", "x" }, "<leader>car", function()
            vim.lsp.buf.code_action({ context = { only = { "refactor" } } })
        end, "LSP refactor actions")
        map("n", "<leader>f", format_buffer, "Format buffer")
        map("n", "<S-M-f>", format_buffer, "Format buffer")
        local function format_selection()
            if vim.bo.filetype == "python" then
                format_buffer({ vim.fn.line("'<"), vim.fn.line("'>") })
            else
                vim.lsp.buf.format({ async = true })
            end
        end
        map("x", "<leader>f", format_selection, "Format selection")
        map("x", "<S-M-f>", format_selection, "Format selection")
        map("i", "<S-M-f>", "<C-o>:FormatBuffer<CR>", "Format buffer")
        map("i", "<C-Space>", vim.lsp.completion.get, "LSP completion")
        vim.keymap.set("i", "<CR>", function()
            if vim.fn.pumvisible() == 0 then return "<CR>" end
            -- CoC accepted the first item on Enter even before moving in its menu.
            return vim.fn.complete_info().selected == -1 and "<C-n><C-y>" or "<C-y>"
        end, { buffer = args.buf, expr = true, silent = true, desc = "Accept completion" })
        vim.keymap.set("i", "<S-CR>", function()
            return vim.fn.pumvisible() == 1 and "<C-e>" or "<S-CR>"
        end, { buffer = args.buf, expr = true, silent = true, desc = "Dismiss completion" })
    end,
})

vim.lsp.enable({
    "lua",
    "pyright",
    "xonsh",
    "typescript",
    "docker",
    "yaml",
    "json",
    "bash",
    "ansible",
    "nix",
    "treesitter_query",
    "fish",
})
