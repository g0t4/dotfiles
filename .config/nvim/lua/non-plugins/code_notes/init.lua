local api = require("non-plugins.werkspaces.api")
local GetPos = require("ask-openai.helpers.wrap_getpos")

-- I'd like to finally have a way to make notes in code and have them show when I revist the code
--   someone built a similar plugin: https://github.com/winter-again/annotate.nvim
--   however AFAICT it only shows a box in the gutter, I'd rather just see extmarks at end of the line
--   and it's marked archived (not maintained)
--   also I can store a JSON file per workspace and avoid complexities of sqlite
--   this can basically be a first extension of my workspace plugin as far as storage is concerned
--
-- FYI IDEAS:
-- - telescope picker to find and review notes
-- - index notes into RAG too! (across repos would be neat)
-- - add column start/end so can be not just line(s)
-- - use `context` to detect moves
-- - add level/type and have the notes show in different colors (more or less noticeable)




---@class CodeNote
---@field start_line_base1 integer
---@field end_line_base1 integer
---@field text string
---@field context string --- for matching moved lines

---@class CodeNotesModule
local M = {}

---@type table<string, CodeNote[]>
M.notes_by_file = {
    -- hard coded set of examples
    [".config/nvim/lua/non-plugins/code_notes/init.lua"] = {
        {
            start_line_base1 = 3,
            end_line_base1 = 5,
            text = "What the FUCK?",
            context = "",
        },
        {
            start_line_base1 = 21,
            end_line_base1 = 22,
            text = "This is the key to understanding how the endpoint responds to foo!",
            context = "",
        }
    }
}

-- ONLY change to a nested dir and/or sqlite as I have issues with this simple setup:
local CODE_NOTES_PATH = "/code_notes.json"

local function load_notes()
    M.notes_by_file = api.read_json_werkspace_file(CODE_NOTES_PATH) or {}
end

function M.add_note(text)
    local bufnr = 0
    local file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    M.notes_by_file[file_path] = M.notes_by_file[file_path] or {}

    local selection = GetPos.CurrentSelection()
    table.insert(M.notes_by_file[file_path], {
        -- TODO get cols too?
        start_line_base1 = selection.start_line_b1,
        end_line_base1 = selection.end_line_b1,
        text = "DUCKARD!",
        -- context = ?
    })

    api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
end

function M.setup()
    local notes_ns_id = vim.api.nvim_create_namespace("code_notes")

    local GLOBAL_NS = 0 -- not using notes_ns_id for highlights
    vim.api.nvim_set_hl(GLOBAL_NS, "CodeNoteText", { fg = "#ff8800", bg = "#2c2c2c", italic = true })
    vim.api.nvim_set_hl(GLOBAL_NS, "CodeNoteSelection", { fg = "#2c2c2c", bg = "#ff8800", italic = true })


    -- TODO uncomment to test real notes
    -- load_notes()

    vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function(event)
            local absolute_path = event.file
            -- TODO fix to always be relative to the workspace dir (not the CWD)
            local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
            -- print("absolute_path", absolute_path)
            -- print("relative_path", relative_path)
            local notes = M.notes_by_file[relative_path]
            if not notes then
                return
            end
            -- vim.print(notes)
            for _, n in ipairs(notes) do
                local start_col_base0 = 0
                local start_line_base0 = n.start_line_base1 - 1

                vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
                    event.buf, notes_ns_id, start_line_base0, start_col_base0,
                    { virt_text = { { n.text, "CodeNoteText" } }, virt_text_pos = "eol", sign_text = "◆" }
                )

                local end_col_base0 = 0
                local end_line_base0 = n.end_line_base1 - 1

                vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
                    event.buf,
                    notes_ns_id,
                    start_line_base0,
                    start_col_base0,
                    {
                        virt_text = { { n.text, "codenotetext" } },
                        virt_text_pos = "eol",
                        sign_text = "◆",
                        -- highlight the selected range
                        end_line = end_line_base0,
                        end_col = end_col_base0,
                        hl_group = "CodeNoteSelection",
                        hl_mode = "combine",
                    }
                )
            end
        end,
    })

    -- TODO later worry about lazy loading this on BufReadPost as a plugin
end

return M
