--
-- FYI! this is turning into my own treesitter custom config (not just harmony)

local ok, err = pcall(function()
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


-- Injection + COC integration => set a virtual filetype for coc completions

-- FYI can change type w/ mapping
--   :CocCommand document.echoFiletype
-- vim.cmd([[
-- let g:coc_filetype_map = {
--     \ 'test': 'harmony'
--  \ }
-- ]])
-- local copy = vim.g.coc_filetype_map or {}
-- copy.test = "harmony"
-- vim.print(copy.test)
-- vim.g.coc_filetype_map = copy

-- vim.api.nvim_create_autocmd("BufReadPost", {
--     callback = function(args)
--         local bufnr = args.buf
--
--         local parser = vim.treesitter.get_parser(bufnr, "harmony")
--         parser:register_cbs({
--             on_changedtree = function(changes, tree)
--                 rescan_injections(bufnr, tree)
--             end,
--         })
--
--         -- initial scan
--         local tree = parser:parse()[1]
--         rescan_injections(bufnr, tree)
--     end,
-- })

-- vim.api.nvim_create_autocmd("FileType", {
--     callback = function(args)
--         vim.print("FILETYPE:", vim.bo.filetype)
--     end,
-- })

-- TODO what event to use? BufReadPost is before filetype == "test"... what about FileType event? pattern=test?
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("TestTSCallbacks", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        if vim.bo[bufnr].filetype ~= "test" then
            -- print("shit filetype isnt test")
            return
        end

        local parser = vim.treesitter.get_parser(bufnr)
        if not parser then
            -- print("FUCK FUCK FUCK - NO PARSER")
            return
        end

        local GetPos = require("ask-openai.helpers.wrap_getpos") -- delay so plugin is loaded

        parser:register_cbs({
            on_changedtree = function(_, tree)
                vim.print("changed tree:")
                local root = tree:root()
                local injections_query = vim.treesitter.query.get("test", "injections")

                local cursor = GetPos.cursor_position()

                vim.print("  cursor:", cursor)
                ---@param ts_node TSNode
                function cursor:is_in_node(ts_node)
                    -- TODO! move to result of cursor_position (new type needed)

                    local row_start_base0, col_start_base0, row_end_base0, col_end_base0 = ts_node:range()
                    print("  row_start0:", row_start_base0, ", col_start0:", col_start_base0)
                    print("  => row_end0:", row_end_base0, ", col_end0:", col_end_base0)
                    local cursor_line_base0 = cursor.line_base1 - 1
                    local cursor_col_base0 = cursor.col_base1 - 1
                    local in_line_range = cursor_line_base0 > row_start_base0 and cursor_line_base0 < row_end_base0
                    local on_start_line = cursor_line_base0 == row_start_base0 and cursor_col_base0 >= col_start_base0
                    local on_end_line = cursor_line_base0 == row_end_base0 and cursor_col_base0 <= col_end_base0
                    return in_line_range or on_start_line or on_end_line
                end

                for pattern, match, metadata in injections_query:iter_matches(root, bufnr, 0, -1) do
                    for id, nodes in pairs(match) do
                        local name = injections_query.captures[id]
                        print("  name:", name)
                        for node_id, node in ipairs(nodes) do
                            print("  node_id:", node_id)
                            print("  type:", node:type())

                            if cursor:is_in_node(node) then
                                print("  cursor IS IN RANGE OF", name)
                            else
                                print("  cursor NOT in range of", name)
                            end

                            -- `node` was captured by the `name` capture in the match

                            -- local node_data = metadata[node_id] -- Node level metadata
                            -- print("  node_data:", node_data)
                            -- print("    range:", node_data.range)
                        end
                    end
                end

                -- for _, match, _ in query:iter_matches(root, 0) do
                --     local node = match[1]
                --     local lang = match["injection.language"] -- custom metadata
                --     -- local sr, sc, er, ec = node:range()
                --     -- store this somewhere
                --     vim.print("  match:", node, lang)
                -- end
            end,
        })
    end,
})
--
-- local function ft_at_cursor()
--     local pos = vim.api.nvim_win_get_cursor(0)
--     local row, col = pos[1] - 1, pos[2]
--
--     for _, id, data in vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true }) do
--         if data.user_data and data.user_data.injected_ft then
--             local r1, c1, r2, c2 = data.row, data.col, data.end_row, data.end_col
--             if row >= r1 and row <= r2 and (row ~= r2 or col < c2) then
--                 return data.user_data.injected_ft
--             end
--         end
--     end
--     return vim.bo.filetype
-- end
