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
--
-- Changes (notes, don't try to solve this yet... get notes working...
--   and then over time see how changes work out before "solving" them)
-- - store git commit sha to track changes?
-- - store context lines and try to relocate on move? or at least flag notes that need fixed




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

    local selection = GetPos.current_selection()
    table.insert(M.notes_by_file[file_path], {
        -- TODO get cols too?
        start_line_base1 = selection.start_line_base1,
        end_line_base1 = selection.end_line_base1,
        text = "DUCKARD!",
        -- context = ?
    })

    -- api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    show_notes()
end

function M.setup()
    -- do return end

    local notes_ns_id = vim.api.nvim_create_namespace("code_notes")

    local GLOBAL_NS = 0 -- not using notes_ns_id for highlights
    vim.api.nvim_set_hl(GLOBAL_NS, "CodeNoteText", { fg = "#ff8800", bg = "#2c2c2c", italic = true, })
    vim.api.nvim_set_hl(GLOBAL_NS, "CodeNoteSelection", { fg = "#2c2c2c", bg = "#ff8800", })
    vim.api.nvim_set_hl(GLOBAL_NS, "CodeNoteGutterIcon", { fg = "#ff8800", })


    -- TODO uncomment to test real notes
    -- load_notes()

    function show_notes()
        local bufnr = 0
        local absolute_path = vim.api.nvim_buf_get_name(bufnr)
        -- TODO fix to always be relative to the workspace dir (not the CWD) .. so if I open from nested dir in repo, I don't lose notes!
        local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
        -- print("absolute_path", absolute_path)
        -- print("relative_path", relative_path)
        local notes = M.notes_by_file[relative_path]
        if not notes then
            return
        end

        for _, n in ipairs(notes) do
            local start_col_base0 = 0
            local start_line_base0 = n.start_line_base1 - 1
            local end_col_base0 = 0
            local end_line_base0 = n.end_line_base1 - 1

            local notes_only = false -- TODO add command to toggle this, store last somehow

            -- * show notes only
            if notes_only then
                vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
                    bufnr, notes_ns_id, start_line_base0, start_col_base0,
                    {
                        virt_text = { { n.text, "CodeNoteText" } },
                        virt_text_pos = "eol",

                        -- gutter indicator (all lines) - especially useful when not selecting text
                        sign_text = "◆",
                        sign_hl_group = "CodeNoteGutterIcon",

                        -- TODO last line inclusive? which convention should I follow (look at GetPos for any ideas there)
                        end_line = end_line_base0,
                        end_col = end_col_base0,
                        -- hl_group = "CodeNoteSelection",
                        -- hl_mode = "combine",
                    }
                )
            else
                -- * show both notes AND highlight the selected, actual text
                vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
                    bufnr,
                    notes_ns_id,
                    start_line_base0,
                    start_col_base0,
                    {
                        -- show note text on first line:
                        virt_text = { { n.text, "CodeNoteText" } }, -- FYI virtual text has the notes to append to end of line (this is in addition to highlighting the actual, selected text)
                        virt_text_pos = "eol",

                        -- gutter indicator (all lines)
                        sign_text = "◆",
                        sign_hl_group = "CodeNoteGutterIcon",

                        -- also, highlight selected text:
                        -- TODO last line inclusive? which convention should I follow (look at GetPos for any ideas there)
                        --   FYI right now... the last line is marked even though end_col is set to 0... so really not included!
                        end_line = end_line_base0,
                        end_col = end_col_base0,
                        hl_group = "CodeNoteSelection",
                        hl_mode = "combine",
                    }
                )
            end
        end
    end

    vim.api.nvim_create_autocmd("BufReadPost", {
        callback = show_notes
    })

    -- TODO this should be a command, and the plugin should be lazy loaded
    vim.api.nvim_create_user_command("AddNote", M.add_note, {})

    -- TODO later worry about lazy loading this on BufReadPost as a plugin
end

return M
