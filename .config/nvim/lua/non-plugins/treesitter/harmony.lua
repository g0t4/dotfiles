vim.treesitter.language.add('harmony', { path = "/Users/wesdemos/repos/github/g0t4/tree-sitter-openai-harmony/openai-harmony.dylib" })



vim.api.nvim_set_hl(0, "@harmony_message_system", { fg = "#4FAFE7" })
vim.api.nvim_set_hl(0, "@harmony_message_developer", { fg = "#4FAFE7" })
vim.api.nvim_set_hl(0, "@harmony_message_user", { fg = "#a99fff" })
-- vim.api.nvim_set_hl(0, "@harmony_message_assistant", { fg = "" })
vim.api.nvim_set_hl(0, "@harmony_message_assistant_analysis", { fg = "#FFC379" })
vim.api.nvim_set_hl(0, "@harmony_message_assistant_commentary", { fg = "#f99fff" })
vim.api.nvim_set_hl(0, "@harmony_message_tool_result", { fg = "#ff00ce" })
vim.api.nvim_set_hl(0, "@harmony_message_assistant_final", { fg = "#d2ffa5" })
vim.api.nvim_set_hl(0, "@is_json", { fg = "#ffffff" })

local harmony_spacing_ns = vim.api.nvim_create_namespace("harmony_spacing")

local function set_extmarks_between_messages(bufnr)
    local query_start_nodes = vim.treesitter.query.parse("harmony", [[
  (start_token) @new_msg
]])

    function color_every_other(tree)
        vim.api.nvim_buf_clear_namespace(bufnr, harmony_spacing_ns, 0, -1)
        local root = tree:root()

        -- TODO would really like virtual line breaks...
        --   isn't this doable?! btw this is an area where my predictions engine is technically broken (it won't show end of line on a subsequent line if multiple lines predicted! but it accepts that way (as it should)

        local count = 0
        for id, node in query_start_nodes:iter_captures(root, 0) do
            -- vim.print(id, node)
            local row_base0, col_base0 = node:start()
            -- print("  ", row_base0, col_base0)
            -- vim.api.nvim_buf_set_extmark(bufnr, harmony_spacing_ns, row_base0, col_base0, {
            --     -- virt_text        = { { "👈" } }, -- works for inline marker (actually, this might be fine, but then why not just use color?)
            --     virt_text     = { { "⤷ ", "Comment" } },
            --     virt_text_pos = "inline",
            --     -- seems like extmarks at best can insert text "inline" but cannot add a \n in that text
            -- })
            local row_end0, col_end0 = node:end_()
            -- print("start", node:start())
            -- print("  end", node:end_())
            if count % 2 == 0 then
                vim.api.nvim_buf_set_extmark(bufnr, harmony_spacing_ns, row_base0, col_base0, {
                    -- hl_group = "Comment",
                    end_row = row_end0,
                    end_col = col_end0,
                    hl_mode = "combine",
                    hl_eol = false,
                    priority = 100,
                    -- optional: add a background highlight for alternating messages
                    hl_group = "@harmony_even"

                })
            end
            count = count + 1

            -- TODO scan system message for "Reasoning: ___" and mark it with extmarks? to color it
        end
    end

    function annotate_start(tree)
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
    -- local tree = parser:parse()[1]
    -- redo(tree)

    -- TODO on every change, insert splits... redo extmarks
    parser:register_cbs({
        on_changedtree = function(changes, tree)
            color_every_other(tree)
        end,
    })
end
