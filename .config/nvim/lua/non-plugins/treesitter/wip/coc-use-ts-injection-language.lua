--
-- *****! NOT USING THIS
do return end
-- Injection + COC integration => set a virtual filetype for coc completions
-- FYI! the below is an experiment to see if I can get CoC to work with injected language from tree-sitter
-- FYI I got the parsing of injection working
--   but I would need to cache that and/or just update it
--   when I trigger a completion
--
--   and I need to solve the problem of getting Coc to recognize the new mapping, it seems to read the global mapping on startup once
--     b/c even when the map changes, due to moving to a diff section of document... coc still shows completions (snippets are easy to see, i.e. _msg in harmony section)
--        or it shows diagnostics of a failure when query starts as "query"(scm files)... and squiggles entire .test corpus doc in this case
--        so you can restart to get coc to read a new value and test that
--        but after that changing the map alone isn't yet working
--        and would need to find a way to change it back when you change sections
--        AND.... actually... you'll have to deal with invalid diagnostics between sections so...
--        yeah this may not work out well beyond if you can get completions to trigger and only override coc file type for that completion's duration.. even still squiggles would suck
--         need to find an official mechanism in Coc (or use alternative like nvim lsp client if it has a mechanism)
--          MIGHT NOT BE DOABLE!!



--

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

-- TODO what event to use? BufReadPost is before filetype == "test"... what about FileType event? pattern=test?
-- vim.api.nvim_create_autocmd("FileType", {
--     callback = function(args)
--         vim.print("FILETYPE:", vim.bo.filetype)
--     end,
-- })
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("TestTSCallbacks", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        local filetype = vim.bo[bufnr].filetype
        if filetype ~= "test" then
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
                local root = tree:root()
                local injections_query = vim.treesitter.query.get("test", "injections")
                local cursor = GetPos.cursor_position()

                for pattern_id, match, metadata, tree in injections_query:iter_matches(root, bufnr, 0, -1) do
                    -- print("\n## match:")
                    -- vim.print("  pattern: " .. vim.inspect(pattern_id))
                    -- vim.print("  match: " .. vim.inspect(match))
                    -- vim.print("  metadata: " .. vim.inspect(metadata))
                    -- vim.print("  tree: " .. vim.inspect(tree))
                    -- vim.print("  \n\n")

                    local hard_coded_language = metadata["injection.language"] -- hardcoded case "injection.language" and not using capture group @injection.language
                    -- print("  hardcoded use_language:", hard_coded_language)
                    local captured_injection_language_node = nil
                    local captured_injection_content_node = nil
                    for id, nodes in pairs(match) do
                        local node = nodes[1] -- seems like only need first node in array
                        local name = injections_query.captures[id]
                        -- print("  id", id)
                        -- print("  node", node)
                        -- print("  name:", name)
                        -- FYI might be other scenarios I have yet to cover (i.e. include children...) ... do that when I encounter it

                        -- unsure about order so look for both and then after loop I can react
                        if name == "injection.language" then
                            captured_injection_language_node = node
                        elseif name == "injection.content" then
                            captured_injection_content_node = node
                        end
                    end
                    -- print("  captured_injection_language_node:", captured_injection_language_node)
                    -- print("  captured_injection_content_node:", captured_injection_content_node)
                    -- print("    range:", captured_injection_content_node:range())
                    if captured_injection_language_node and captured_injection_content_node then
                        if cursor:in_range(captured_injection_content_node) then
                            local in_node = vim.treesitter.get_node_text(captured_injection_content_node, bufnr)
                            -- print("  * IN NODE: ", in_node)
                            local captured_language = vim.treesitter.get_node_text(captured_injection_language_node, bufnr)
                            print("  * WITH LANGUAGE from NODE: ", captured_language)
                            -- temp set coc_filetype
                            -- TODO! dammit! coc seems to only read this once on startup!!
                            local map = vim.g.coc_filetype_map or {}
                            map[filetype] = captured_language
                            vim.g.coc_filetype_map = map
                            return -- stop once we find the node we live inside of
                        end
                    elseif hard_coded_language and captured_injection_content_node then
                        if cursor:in_range(captured_injection_content_node) then
                            local in_node = vim.treesitter.get_node_text(captured_injection_content_node, bufnr)
                            -- print("  * IN NODE: ", in_node)
                            print("  * WITH hardcoded language:", hard_coded_language)
                            -- TODO! dammit! coc seems to only read this once on startup!!
                            local map = vim.g.coc_filetype_map or {}
                            map[filetype] = hard_coded_language
                            vim.g.coc_filetype_map = map
                            return -- stop once we find the node we live inside of
                        end
                    end
                    -- else keep going
                end
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
