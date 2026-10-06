-- Run with: nvim --headless --clean -l tests/nvim/lsp_save_isolation/repro.lua
-- LSP_REPRO_ASK=off is the passing one-server control.
-- LSP_REPRO_SEPARATE_GROUPS=on tests the full-sync workaround for xonsh.
local source = debug.getinfo(1, "S").source:sub(2)
local server = vim.fn.fnamemodify(source, ":h") .. "/server.py"
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local log = dir .. "/messages.jsonl"
local xsh = dir .. "/sample.xsh"
local lua = dir .. "/sample.lua"
vim.fn.writefile({ "x = 1" }, xsh)
vim.fn.writefile({ "local x = 1" }, lua)

local function start(name, file, filetype)
    vim.cmd.edit(file)
    vim.bo.filetype = filetype
    local id = vim.lsp.start({
        name = name,
        cmd = { vim.fn.exepath("python3"), server, name, log },
        root_dir = dir,
        filetypes = { filetype },
        flags = name == "xonsh" and vim.env.LSP_REPRO_SEPARATE_GROUPS == "on"
            and { allow_incremental_sync = false } or nil,
    })
    assert(id, "could not start " .. name)
    assert(vim.wait(5000, function()
        return #vim.lsp.get_clients({ bufnr = 0, name = name }) == 1
    end), "did not attach " .. name)
    return vim.api.nvim_get_current_buf()
end

local xsh_buf = start("xonsh", xsh, "xonsh")
if vim.env.LSP_REPRO_ASK ~= "off" then
    start("ask_ls", lua, "lua")
else
    vim.cmd.edit(lua)
    vim.bo.filetype = "lua"
end
local lua_buf = vim.api.nvim_get_current_buf()
assert(#vim.lsp.get_clients({ bufnr = lua_buf, name = "xonsh" }) == 0,
    "xonsh unexpectedly attached to Lua")
vim.cmd.write()
vim.cmd.edit(xsh)
vim.cmd.write()
vim.wait(300, function() return false end)

local events = {}
if vim.fn.filereadable(log) == 1 then
    for _, line in ipairs(vim.fn.readfile(log)) do
        events[#events + 1] = vim.json.decode(line)
    end
end
local function recipients(method, uri)
    local names = {}
    for _, event in ipairs(events) do
        if event.method == method and event.uri == uri then
            names[#names + 1] = event.server
        end
    end
    table.sort(names)
    return names
end
local lua_uri = vim.uri_from_bufnr(lua_buf)
local xsh_uri = vim.uri_from_bufnr(xsh_buf)
local lua_expected = vim.env.LSP_REPRO_ASK == "off" and {} or { "ask_ls" }
local lua_saves = recipients("textDocument/didSave", lua_uri)
local xsh_saves = recipients("textDocument/didSave", xsh_uri)
print("Lua didOpen recipients: " .. vim.inspect(recipients("textDocument/didOpen", lua_uri)))
print("Xonsh didOpen recipients: " .. vim.inspect(recipients("textDocument/didOpen", xsh_uri)))
print("Lua didSave recipients: " .. vim.inspect(lua_saves))
print("Xonsh didSave recipients: " .. vim.inspect(xsh_saves))
assert(vim.deep_equal(recipients("textDocument/didOpen", lua_uri), lua_expected),
    "Lua didOpen reached an unrelated LSP")
assert(vim.deep_equal(recipients("textDocument/didOpen", xsh_uri), { "xonsh" }),
    "Xonsh didOpen reached an unrelated LSP")
assert(vim.deep_equal(lua_saves, lua_expected), "Lua didSave reached an unrelated LSP")
assert(vim.deep_equal(xsh_saves, { "xonsh" }), "Xonsh didSave reached an unrelated LSP")
vim.cmd.quitall({ bang = true })
