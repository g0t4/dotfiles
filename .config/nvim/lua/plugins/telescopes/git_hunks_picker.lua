local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local make_entry = require("telescope.make_entry")
local putils = require("telescope.previewers.utils")
local log = require("devtools.logs.logger").universal()

local M = {}

local function parse_diff(lines)
    local results = {}
    local current

    for _, line in ipairs(lines) do
        local path = line:match("^%+%+%+ b/(.+)")
        if path then
            current = path
        else
            local old_start, old_count, new_start, new_count =
                line:match("^@@ %-(%d+),?(%d*) %+([0-9]+),?(%d*) @@")

            if current and new_start then
                table.insert(results, {
                    path = current,
                    lnum = tonumber(new_start),
                    old_start = tonumber(old_start),
                    old_count = tonumber(old_count ~= "" and old_count or 1),
                    new_count = tonumber(new_count ~= "" and new_count or 1),
                    header = line,
                })
            end
        end
    end

    return results
end

M.git_hunks = function(opts)
    opts = opts or {}

    -- FYI GH issue closed as not planned:
    --   https://github.com/nvim-telescope/telescope.nvim/issues/3341
    --   seems like there's no interest in jumping to the hunk you selected in the telescope picker
    --   very strange IMO
    --   why would I want to pick a changed hunk (could even be multiple in a file)
    --     and then jump to the start of the file?
    --     only to then have to step through hunks (if I have gitsigns)
    --     until I land on the hunk I already selected?

    local cmd = {
        "git",
        "diff",
        "--unified=0",
        "--no-color",
    }
    if opts.staged then
        table.insert(cmd, "--staged")
    end
    log:warn(cmd)

    local output = vim.fn.systemlist(cmd)


    if vim.v.shell_error ~= 0 then
        vim.notify("git diff failed", vim.log.levels.ERROR)
        return
    end

    local hunks = parse_diff(output)

    pickers.new(opts, {
        prompt_title = "Git Hunks",

        finder = finders.new_table({
            results = hunks,

            entry_maker = function(entry)
                return {
                    value = entry,

                    ordinal = entry.path .. " " .. entry.header,

                    display = string.format(
                        "%s:%d  +%d -%d",
                        entry.path,
                        entry.lnum,
                        entry.new_count,
                        entry.old_count
                    ),

                    filename = entry.path,
                    lnum = entry.lnum,

                    path = entry.path,
                }
            end,
        }),

        sorter = conf.generic_sorter(opts),

        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                log:info("selected entry", entry)

                previewers.buffer_previewer_maker(
                    entry.filename,
                    self.state.bufnr,
                    {
                        bufname = self.state.bufname,
                        callback = function(bufnr)
                            vim.schedule(function()
                                local winid = self.state.winid
                                if vim.api.nvim_win_is_valid(winid) then
                                    vim.api.nvim_win_set_cursor(winid, {
                                        entry.lnum,
                                        0,
                                    })
                                    vim.api.nvim_win_call(winid, function()
                                        vim.cmd.normal({ "zz", bang = true })
                                    end)
                                end

                                local end_line = entry.lnum + entry.value.new_count - 1

                                vim.hl.range(
                                    bufnr,
                                    vim.api.nvim_create_namespace("git_hunks"),
                                    "Visual",
                                    { entry.lnum - 1, 0 },
                                    { end_line, 0 }
                                )
                            end)
                        end,
                    }
                )
            end,
        })


    }):find()
end

function M.setup()
    vim.keymap.set("n", "<leader>gst", function()
        -- I used to have gst to match my gst fish abbr... but this is best put under `gd` for git diff
        --  and gdc for staged... I use both of these as fish abbrs too
        vim.notify("Use <leader>gd instead of <leader>gst for git hunks", vim.log.levels.INFO)
    end)
    vim.keymap.set("n", "<leader>gd", M.git_hunks)
    vim.keymap.set("n", "<leader>gdc", function()
        M.git_hunks({ staged = true })
    end)
end

return M
