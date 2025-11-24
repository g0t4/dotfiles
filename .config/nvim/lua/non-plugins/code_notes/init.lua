local api = require('non-plugins.werkspaces.api')
local GetPos = require('ask-openai.helpers.wrap_getpos')

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
---@field context? NoteContext

---@class NoteContext
---@field before string[]   -- lines before the note, first entry is the line directly before the note
---@field after string[]    -- lines after the note, first entry is the line directly after the note
---@field selection string -- the text selected when the note was added


---@class CodeNotesModule
local M = {}

---@type table<string, CodeNote[]>
M.notes_by_file = {}

---@param buffer_number integer
function M.setup_fake_data(buffer_number)
    M.notes_by_file = {
        -- hard coded set of examples
        [".config/nvim/lua/non-plugins/code_notes/init.lua"] = {
            {
                start_line_base1 = 3,
                end_line_base1 = 5,
                text = "What the FUCK?",
                context = M.slice(buffer_number, 2, 5, 2),
            },
            {
                start_line_base1 = 21,
                end_line_base1 = 22,
                text = "This is the key to understanding how the endpoint responds to foo!",
                context = M.slice(buffer_number, 20, 22, 2),
            }
        }
    }
end

-- ONLY change to a nested dir and/or sqlite as I have issues with this simple setup:
local CODE_NOTES_PATH = "/code_notes.json"

local function load_notes()
    M.notes_by_file = api.read_json_werkspace_file(CODE_NOTES_PATH) or {}
end

---@param buffer_number integer
---@return string relative_path
local function get_relative_path_for_this_file(buffer_number)
    local absolute_path = vim.api.nvim_buf_get_name(buffer_number)
    -- TODO fix to always be relative to the workspace dir (not the CWD) .. so if I open from nested dir in repo, I don't lose notes!
    local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
    -- print("absolute_path", absolute_path)
    -- print("relative_path", relative_path)
    return relative_path
end

---@param buffer_number integer
local function get_or_create_notes_for_this_file(buffer_number)
    local relative_path = get_relative_path_for_this_file(buffer_number)
    local notes = M.notes_by_file[relative_path]
    if not notes then
        notes = {}
        M.notes_by_file[relative_path] = notes
    end
    return notes
end

---@param cursor_line number 0-based line number of the cursor
---@return nil
function M.vim_print_note_command(cursor_line)
    local buffer_number = vim.api.nvim_get_current_buf()
    local note = M.find_first_note_under_cursor(buffer_number)
    if not note then
        print("NO NOTE UNDER CURSOR")
        return
    end
    vim.print(note)

    -- prettier view:
    print("BEFORE")
    print(note.context.before)
    print("")
    print("SELECTED TEXT")
    print(note.context.selection)
    print("")
    print("AFTER")
    print(note.context.after)
end

function M.add_note(text)
    local buffer_number = vim.api.nvim_get_current_buf()
    local selection = GetPos.last_selection()
    local notes = get_or_create_notes_for_this_file(buffer_number)
    local around = 2 -- number of lines before/after to capture too
    local context = M.slice(buffer_number, selection:start_line_base0(), selection:end_line_base0(), around)
    table.insert(notes, {
        -- TODO get cols too? if so, store linewise vs charwise? vs?
        start_line_base1 = selection.start_line_base1,
        end_line_base1 = selection.end_line_base1,
        text = text,
        context = context,
    })

    -- api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    M.show_notes(buffer_number)
end

---@param buffer_number integer
function M.find_first_note_under_cursor(buffer_number)
    -- find first note under cursor to replace
    local pos = GetPos.current_selection() -- TODO would be nice to name this as just cursor position?
    local line = pos.start_line_base1

    local notes = get_or_create_notes_for_this_file(buffer_number)
    for index, n in ipairs(notes) do
        if n.start_line_base1 <= line and n.end_line_base1 >= line then
            return n, index
        end
    end
end

function M.delete_note()
    local buffer_number = vim.api.nvim_get_current_buf()
    local note, index = M.find_first_note_under_cursor(buffer_number)
    if not note then
        print("NO NOTE UNDER CURSOR TO DELETE")
        return
    end
    local notes = get_or_create_notes_for_this_file(buffer_number)
    table.remove(notes, index)
    -- api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    M.show_notes(buffer_number)
end

function M.update_note(text)
    local buffer_number = vim.api.nvim_get_current_buf()
    local note = M.find_first_note_under_cursor(buffer_number)
    if not note then
        print("NO NOTE UNDER CURSOR TO UPDATE")
        return
    end
    note.text = text
    -- api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    M.show_notes(buffer_number)
end

---@param buffer_number integer
function M.show_notes(buffer_number)
    -- * clear notes
    vim.api.nvim_buf_clear_namespace(buffer_number, M.notes_ns_id, 0, -1)

    local notes = get_or_create_notes_for_this_file(buffer_number)

    -- * show each note
    for _, n in ipairs(notes) do
        local start_col_base0 = 0
        local start_line_base0 = n.start_line_base1 - 1
        local end_col_base0 = 0
        local end_line_base0 = n.end_line_base1 - 1

        local notes_only = false -- TODO add command to toggle this, store last somehow

        -- * show notes only
        if notes_only then
            vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
                buffer_number, M.notes_ns_id, start_line_base0, start_col_base0,
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
                buffer_number,
                M.notes_ns_id,
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

---@param buffer_number integer
function M.get_lines(buffer_number, start_line_base0, end_line_exclusive_base0)
    -- TODO merge into GetPosSelectionRange:lines(), or?
    return vim.api.nvim_buf_get_lines(buffer_number, start_line_base0, end_line_exclusive_base0, false)
end

---@param buffer_number integer
function M.slice(buffer_number, start_line_base0, end_line_exclusive_base0, around)
    -- TODO what to do if negative start_line_base0
    -- TODO what about end_line past end of file (more than 1 line past so it means content beyond what is in doc)?

    local before_start_base0 = math.max(start_line_base0 - around, 0)
    local before_end_exclusive_base0 = start_line_base0

    local after_start_base0 = end_line_exclusive_base0
    local after_end_exclusive_base0 = end_line_exclusive_base0 + around

    return {
        before    = table.concat(M.get_lines(buffer_number, before_start_base0, before_end_exclusive_base0), "\n"),
        selection = table.concat(M.get_lines(buffer_number, start_line_base0, end_line_exclusive_base0), "\n"), -- TODO check math on exclusive end line base0
        after     = table.concat(M.get_lines(buffer_number, after_start_base0, after_end_exclusive_base0), "\n"),
    }
end

---@param buffer_number integer
local function TODO_search_in_buf(buffer_number, text)
    if text == "" then return nil end
    local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
    local full = table.concat(lines, "\n")

    local s = full:find(text, 1, true)
    if not s then return nil end

    -- convert byte offset → line start
    local pre = full:sub(1, s)
    local line = select(2, pre:gsub("\n", ""))
    return line + 1 -- base1
end

---@param buffer_number integer
function M.TODO_resolve(buffer_number, note)
    local before = note.before or ""
    local selection = note.selection or ""
    local after = note.after or ""

    -- 1. Try matching BEFORE + SELECTION + AFTER
    local big = table.concat({ before, selection, after }, "\n")
    local line = TODO_search_in_buf(buffer_number, big)
    if line then
        return {
            start_line = line + #vim.split(before, "\n"),
            end_line   = line + #vim.split(before, "\n") + #vim.split(selection, "\n"),
            method     = "full_match",
        }
    end

    -- 2. Try matching exactly the selected text
    local sline = TODO_search_in_buf(buffer_number, selection)
    if sline then
        return {
            start_line = sline,
            end_line   = sline + #vim.split(selection, "\n"),
            method     = "selected_only",
        }
    end

    -- 3. Fallback to stored line numbers
    return {
        start_line = note.start_line_base1,
        end_line   = note.end_line_base1,
        method     = "line_fallback",
    }
end

---@param buffer_number integer
function M.TODO_apply_extmark(buffer_number, ns, note, hlgroup)
    local pos = M.TODO_resolve(buffer_number, note)

    vim.api.nvim_buf_set_extmark(buffer_number, ns, pos.start_line - 1, 0, {
        end_line = pos.end_line - 1,
        hl_group = hlgroup,
    })

    return pos
end

function M.setup()
    -- do return end

    M.notes_ns_id = vim.api.nvim_create_namespace('code_notes')

    local GLOBAL_NS = 0 -- not using notes_ns_id for highlights
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteText', { fg = '#ff8800', bg = '#2c2c2c', italic = true, })
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteSelection', { fg = '#2c2c2c', bg = '#ff8800', })
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteGutterIcon', { fg = '#ff8800', })

    -- TODO uncomment to test real notes
    -- load_notes()

    vim.api.nvim_create_autocmd('BufReadPost', {
        callback = function(info)
            local buffer_number = info.buf
            M.setup_fake_data(buffer_number)
            M.show_notes(buffer_number)
        end
    })

    -- TODO later worry about lazy loading this on BufReadPost as a plugin, or on using command like AddNote
    vim.api.nvim_create_user_command('AddNote',
        function(opts)
            local text = table.concat(opts.fargs, ' ')
            M.add_note(text)
        end,
        { nargs = '*', range = true }
    )
    vim.api.nvim_create_user_command('DeleteNote', M.delete_note, {})
    vim.api.nvim_create_user_command('UpdateNote',
        function(opts)
            local text = table.concat(opts.fargs, ' ')
            M.update_note(text)
        end,
        { nargs = '*', range = true }
    )

    vim.api.nvim_create_user_command('ShowNotes',
        function()
            local buffer_number = vim.api.nvim_get_current_buf()
            M.show_notes(buffer_number)
        end,
        {})
    vim.api.nvim_create_user_command('PrintNote', M.vim_print_note_command, {})
end

return M
