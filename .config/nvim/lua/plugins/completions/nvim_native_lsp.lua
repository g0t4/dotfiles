-- Native LSP for source buffers. Command-line completion stays in cmdline_cmp.lua.
vim.opt.completeopt = { "menuone", "noselect", "popup" }
vim.diagnostic.config({ signs = false, virtual_text = false,
    underline = { severity = { min = vim.diagnostic.severity.INFO } },
    severity_sort = true })

vim.lsp.config("lua_ls", {
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
        python = { analysis = { inlayHints = {
            variableTypes = false, parameterTypes = false, functionReturnTypes = false,
        } } },
    },
})

vim.lsp.config("xonsh", {
    cmd = { "xonsh-lsp", "--stdio" },
    filetypes = { "xonsh" },
    root_markers = { ".xonshrc", "xonshrc", ".git" },
    workspace_required = false,
    init_options = { pythonBackend = "pyright" },
})

local function format_buffer(range)
    if vim.bo.filetype == "xonsh" or vim.bo.filetype == "python" then
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

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("native_lsp_mappings", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
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
            vim.diagnostic.setloclist({ open = true })
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
            vim.lsp.buf.code_action({ range = {
                start = { row, 0 }, ["end"] = { row, #vim.api.nvim_get_current_line() },
            } })
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

vim.lsp.enable({ "lua_ls", "pyright", "xonsh" })
