--
-- FYI! this is turning into my own treesitter custom config (not just harmony)

local ok, err = pcall(function()
    -- TODO move this registration to use nvim-treesitter/nvim-treesitter?
    vim.treesitter.language.add('harmony', {
        path = os.getenv("HOME") .. "/repos/github/g0t4/tree-sitter-openai-harmony/openai-harmony.dylib",
    })
    vim.treesitter.language.add('test', {
        path = os.getenv("HOME") .. "/repos/github/tree-sitter-grammars/tree-sitter-test/test.dylib",
    })
end)
if not ok then
    vim.notify("Failed to load custom treesitter languages: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
end


vim.api.nvim_set_hl(0, "@harmony_message_system", { fg = "#6986ff" })
vim.api.nvim_set_hl(0, "@harmony_start_token", { bold = true })
vim.api.nvim_set_hl(0, "@harmony_message_developer", { fg = "#6AC4EC" })
vim.api.nvim_set_hl(0, "@harmony_message_user", { fg = "#a99fff" })
-- vim.api.nvim_set_hl(0, "@harmony_message_assistant", { fg = "" })
vim.api.nvim_set_hl(0, "@harmony_message_assistant_analysis", { fg = "#FFC379" })
vim.api.nvim_set_hl(0, "@harmony_message_assistant_commentary", { fg = "#f99fff" })
vim.api.nvim_set_hl(0, "@harmony_message_tool_result", { fg = "#fdfd90" })
vim.api.nvim_set_hl(0, "@harmony_message_assistant_final", { fg = "#ffffff" })
vim.api.nvim_set_hl(0, "@is_json", { fg = "#c1c1c1" }) -- mostly to test targeting it, before injecting JSON

local harmony_spacing_ns = vim.api.nvim_create_namespace("harmony_spacing")

local function set_extmarks_between_messages(bufnr)
    local query_start_nodes = vim.treesitter.query.parse("harmony", [[
          (start_token) @new_msg
    ]])

    function annotate_start_of_each_message(tree)
        vim.api.nvim_buf_clear_namespace(bufnr, harmony_spacing_ns, 0, -1)
        local root = tree:root()

        for id, node in query_start_nodes:iter_captures(root, 0) do
            -- vim.print(id, node)
            local row_base0, col_base0 = node:start()
            -- print("  ", row_base0, col_base0)
            vim.api.nvim_buf_set_extmark(bufnr, harmony_spacing_ns, row_base0, col_base0, {
                -- virt_text        = { { "👈" } }, -- works for inline marker (actually, this might be fine, but then why not just use color?)
                virt_text     = { { "⤷ ", "Comment" } },
                virt_text_pos = "inline",
                -- seems like extmarks at best can insert text "inline" but cannot add a \n in that text
            })
            -- TODO scan system message for "Reasoning: ___" and mark it with extmarks? to color it
        end
    end

    local parser = vim.treesitter.get_parser(bufnr, "harmony")
    -- FYI register_cbs is called immediately so I don't need to call redo here, it seems (probably b/c I am adding this early in the FileType event)
    local tree = parser:parse()[1]
    annotate_start_of_each_message(tree)

    parser:register_cbs({
        on_changedtree = function(changes, tree)
            annotate_start_of_each_message(tree)
        end,
    })
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "harmony",
    callback = function(args)
        set_extmarks_between_messages(args.buf)
    end,
})
