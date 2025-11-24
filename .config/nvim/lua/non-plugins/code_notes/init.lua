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
---@field start_line_base1 integer -- INCLUSIVE (naturally)
---@field end_line_base1 integer -- INCLUSIVE (both linewise/charwise)
---@field text string
---@field context? NoteContext

---@class NoteContext
--- TODO should I use [] instead of concat w/ \n for lines?
---@field before string -- lines before the note, first entry is the line directly before the note
---@field after string -- lines after the note, first entry is the line directly after the note
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
                context = M.slice(buffer_number, 2, 5, 2), -- FYI 5 is exclusive b/c it's (6 in base1)
            },
            {
                start_line_base1 = 21,
                end_line_base1 = 22,
                text = "This is the key to understanding how the endpoint responds to foo!",
                context = M.slice(buffer_number, 20, 22, 2), -- FYI 22 is exclusive b/c its (23 in base1)
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
---@return table
local function get_sorted_notes_for_this_file(buffer_number)
    local relative_path = get_relative_path_for_this_file(buffer_number)
    local notes = M.notes_by_file[relative_path] or {}
    table.sort(notes, function(a, b)
        if a.start_line_base1 == b.start_line_base1 then
            return a.end_line_base1 < b.end_line_base1
        end
        return a.start_line_base1 < b.start_line_base1
    end)
    return notes
end

---@param buffer_number integer
local function get_notes_for_this_file(buffer_number)
    local relative_path = get_relative_path_for_this_file(buffer_number)
    return M.notes_by_file[relative_path] or {}
end

---@param cursor_line number 0-based line number of the cursor
---@return nil
function M.vim_print_note_command(cursor_line)
    local buffer_number = vim.api.nvim_get_current_buf()
    local _, note = M.find_first_note_under_cursor(buffer_number)
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
    if selection:no_prior_selection() then
        print("NO SELECTION - select text before adding a note")
        return
    end

    local notes = get_notes_for_this_file(buffer_number)
    local around = 2 -- number of lines before/after to capture too
    local context = M.slice(buffer_number, selection:start_line_base0(), selection:end_line_base0(), around)
    table.insert(notes, {
        -- TODO get cols too? if so, store linewise vs charwise? vs?
        start_line_base1 = selection.start_line_base1,

        -- selection.end_line_base1 is INCLUSIVE per my testing of selections (both linewise and charwise)... so I need to adjust mapping to exclusive when showing
        end_line_base1 = selection.end_line_base1,

        text = text,
        context = context,
    })

    -- ensure set, if it was a new, empty list
    local relative_path = get_relative_path_for_this_file(buffer_number)
    M.notes_by_file[relative_path] = notes

    -- then, quick hack to sort them
    M.notes_by_file[relative_path] = get_sorted_notes_for_this_file(buffer_number)

    -- PRN pretty print the json?
    api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    M.show_notes(buffer_number)
end

---@param buffer_number integer
---@return integer|nil index, CodeNote|nil note   -- index of the matching note (or nil) and the note itself
function M.find_first_note_under_cursor(buffer_number)
    -- find first note under cursor to replace
    local cursor = GetPos.cursor_position()

    local notes = get_notes_for_this_file(buffer_number)
    for index, note in ipairs(notes) do
        if note.start_line_base1 <= cursor.line_base1 and note.end_line_base1 >= cursor.line_base1 then
            return index, note
        end
    end
end

function M.delete_note()
    local buffer_number = vim.api.nvim_get_current_buf()
    local index, note = M.find_first_note_under_cursor(buffer_number)
    if not index then
        print("NO NOTE UNDER CURSOR TO DELETE")
        return
    end
    local notes = get_notes_for_this_file(buffer_number)
    table.remove(notes, index)
    api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    M.show_notes(buffer_number)
end

---@param text string
function M.update_note(text)
    local buffer_number = vim.api.nvim_get_current_buf()
    local _, note = M.find_first_note_under_cursor(buffer_number)
    if not note then
        print("NO NOTE UNDER CURSOR TO UPDATE")
        return
    end
    note.text = text
    api.write_json_werkspace_file(CODE_NOTES_PATH, M.notes_by_file)
    M.show_notes(buffer_number)
end

---@param buffer_number integer
---@param note CodeNote
function M.apply_extmarks(buffer_number, note)
    local start_col_base0 = 0
    local start_line_base0 = note.start_line_base1 - 1

    local end_col_base0 = 0
    local end_line_inclusive_base0 = note.end_line_base1 - 1

    -- TODO add command to toggle this, store last somehow
    -- local highlight_lines = false
    local highlight_lines = true

    -- * extmark for text + gutter icons
    vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
        buffer_number, M.notes_ns_id,
        start_line_base0,
        start_col_base0,
        {
            -- * note text goes onto end of first line
            virt_text = { { note.text, "CodeNoteText" } },
            virt_text_pos = "eol",

            -- * gutter "sign" indicator (all lines in range) - especially useful when not highlight_lines
            sign_text = "◆",
            sign_hl_group = "CodeNoteGutterIcon",

            end_line = end_line_inclusive_base0, -- extmarks use INCLUSIVE end line!
            -- FYI gutter icon shows on end_line too! (inclusive)
        }
    )
    if highlight_lines then
        -- * extmark to highlight the selected, actual text
        vim.api.nvim_buf_set_extmark( -- (0,0)-indexed
            buffer_number,
            M.notes_ns_id,
            -- start highlighter at start of first line
            start_line_base0,
            start_col_base0,
            {
                -- highlight thru line after end_line, to its first character (col=0)
                -- => effectively none of the last line
                -- => BUT, this ensures the last line of the selection is fully highlighted
                -- otherwise I'd have to compute end_col based on content... yuck! or smth else?
                -- FYI needing different values for end_line is why I split out this second extmark for just the highlighter
                --   if I try to merge back into the first, I get a gutter icon on the line after... which I don't want
                end_line = end_line_inclusive_base0 + 1, -- extmarks use INCLUSIVE end line
                end_col = end_col_base0,

                -- * highlighting:
                hl_group = "CodeNoteSelection",
                -- hl_mode = "combine", -- not sure I need this?
            }
        )
    end
end

---@param buffer_number integer
function M.show_notes(buffer_number)
    -- * clear notes
    vim.api.nvim_buf_clear_namespace(buffer_number, M.notes_ns_id, 0, -1)
    -- FYI in all of my time working with extmarks, I have yet to notice performance issues => hence just recreate all of them!

    local notes = get_notes_for_this_file(buffer_number)

    -- * show each note
    for _, n in ipairs(notes) do
        M.apply_extmarks(buffer_number, n)
    end
end

---@param buffer_number integer
function M.get_lines(buffer_number, start_line_base0, end_line_exclusive_base0)
    -- TODO merge into GetPosSelectionRange:lines(), or?
    return vim.api.nvim_buf_get_lines(buffer_number,
        start_line_base0,
        end_line_exclusive_base0,
        false -- ignore out of bounds, not an error (will only take what is present, i.e. if end_line is past end of file)
    )
end

---@param buffer_number integer
function M.slice(buffer_number, start_line_base0, end_line_exclusive_base0, around)
    -- TODO what to do if negative start_line_base0

    local before_start_base0 = math.max(start_line_base0 - around, 0)
    local before_end_exclusive_base0 = start_line_base0

    local after_start_base0 = end_line_exclusive_base0
    local after_end_exclusive_base0 = end_line_exclusive_base0 + around

    return {
        before    = table.concat(M.get_lines(buffer_number, before_start_base0, before_end_exclusive_base0), "\n"),
        selection = table.concat(M.get_lines(buffer_number, start_line_base0, end_line_exclusive_base0), "\n"),
        after     = table.concat(M.get_lines(buffer_number, after_start_base0, after_end_exclusive_base0), "\n"),
    }
end

---@param buffer_number integer
local function TODO_search_in_buf(buffer_number, text)
    if text == "" then return nil end
    -- TODO... woa... ChatGPT WTF... this can't be done on each note!! pass this in or otherwise cache it (and multiple times per the same line, yikes!)
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
---@param note CodeNote
function M.TODO_resolve(buffer_number, note)
    local before_text = note.context.before or ""
    local selection_text = note.context.selection or ""
    local after_text = note.context.after or ""

    -- TODO me thinks, use selection numbers and if they selection lines match alone then stop
    --  fallback => search for selection/after/before
    --  fallback => fuzzy search as a last resort (or maybe levenshtein distance)
    --
    --  FYI if fallback is needed, might want to consider changing color slightly to indicate that smth is different? especially if using fuzzy match

    -- 0. TODO get selection text and check for a match, before searching

    -- 1. Try matching BEFORE + SELECTION + AFTER
    local all_text = table.concat({ before_text, selection_text, after_text }, "\n")
    local line = TODO_search_in_buf(buffer_number, all_text)
    if line then
        return {
            start_line = line + #vim.split(before_text, "\n"),
            end_line   = line + #vim.split(before_text, "\n") + #vim.split(selection_text, "\n"),
            method     = "full_match",
        }
    end

    -- 2. Try matching exactly the selected text
    local sline = TODO_search_in_buf(buffer_number, selection_text)
    if sline then
        return {
            start_line = sline,
            end_line   = sline + #vim.split(selection_text, "\n"),
            method     = "selected_only",
        }
    end

    -- 3. Fallback to stored line numbers
    --  TODO or show at top of file? with blue color or smth... ? or redish?
    return {
        start_line = note.start_line_base1,
        end_line   = note.end_line_base1,
        method     = "line_fallback",
    }
end

function M.setup()
    -- do return end

    M.notes_ns_id = vim.api.nvim_create_namespace('code_notes')

    local GLOBAL_NS = 0 -- not using notes_ns_id for highlights
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteText', { fg = '#ff8800', bg = '#2c2c2c', italic = true, })
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteSelection', { fg = '#2c2c2c', bg = '#ff8800', })
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteGutterIcon', { fg = '#ff8800', })

    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteTextFallback', { fg = '#ffcc00', bg = '#3a3a3a', italic = true })
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteSelectionFallback', { fg = '#3a3a3a', bg = '#ffcc00' })
    vim.api.nvim_set_hl(GLOBAL_NS, 'CodeNoteGutterIconFallback', { fg = '#ffcc00' })

    load_notes()

    vim.api.nvim_create_autocmd('BufReadPost', {
        callback = function(info)
            local buffer_number = info.buf
            -- M.setup_fake_data(buffer_number)
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


    ---@param buffer_number integer
    ---@return integer|nil index, CodeNote|nil note
    function M.find_next_note_under_cursor(buffer_number)
        local cursor = GetPos.cursor_position()
        local notes = get_sorted_notes_for_this_file(buffer_number)
        for index = 1, #notes do
            local note = notes[index]
            if note.start_line_base1 > cursor.line_base1 then
                return index, note
            end
        end
        return nil, nil
    end

    ---@param buffer_number integer
    ---@return integer|nil index, CodeNote|nil note
    function M.find_prev_note_under_cursor(buffer_number)
        local cursor = GetPos.cursor_position()
        local notes = get_sorted_notes_for_this_file(buffer_number)
        for index = #notes, 1, -1 do
            local note = notes[index]
            if note.end_line_base1 < cursor.line_base1 then
                return index, note
            end
        end
        return nil, nil
    end

    function M.jump_to_note(buffer_number, note)
        if not note then return end
        vim.api.nvim_win_set_cursor(0, { note.start_line_base1, 0 })
        M.show_notes(buffer_number)
    end

    function M.next_note()
        local buffer_number = vim.api.nvim_get_current_buf()
        local _, note = M.find_next_note_under_cursor(buffer_number)
        if not note then
            print("No next note")
            return
        end
        M.jump_to_note(buffer_number, note)
    end

    function M.prev_note()
        local buffer_number = vim.api.nvim_get_current_buf()
        local _, note = M.find_prev_note_under_cursor(buffer_number)
        if not note then
            print("No previous note")
            return
        end
        M.jump_to_note(buffer_number, note)
    end

    vim.api.nvim_create_user_command('NextNote', function()
        M.next_note()
    end, {})

    vim.api.nvim_create_user_command('PrevNote', function()
        M.prev_note()
    end, {})

    ---@param buffer_number integer
    function M.list_notes(buffer_number)
        local notes = get_sorted_notes_for_this_file(buffer_number)
        if #notes == 0 then
            print("No notes in this file")
            return
        end
        for _, note in ipairs(notes) do
            vim.print({
                -- FYI prints as a signle line - compact, which is a nice way to see this, I can add more info later
                note.start_line_base1,
                note.end_line_base1,
                note.text,
            })
        end
    end

    vim.api.nvim_create_user_command('ListNotes', function()
        local buffer_number = vim.api.nvim_get_current_buf()
        M.list_notes(buffer_number)
    end, {})


    vim.api.nvim_create_user_command('PrintNote', M.vim_print_note_command, {})
end

return M
