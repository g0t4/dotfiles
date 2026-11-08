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

---@param rev string
---@param path string
---@return string filepath to use for previewing
local function preview_filepath(rev, path)
    if not rev then
        return path
    end

    local output = vim.fn.systemlist({ "git", "show", rev .. ":" .. path })
    if vim.v.shell_error ~= 0 then
        vim.notify("git show " .. rev .. ":" .. path .. " failed", vim.log.levels.WARN)
        return path
    end

    local tmp = vim.fn.tempname()
    local ext = path:match("%.([^.]+)$")
    if ext then
        tmp = tmp .. "." .. ext
    end
    vim.fn.writefile(output, tmp)
    return tmp
end

M.git_hunks = function(opts)
    opts = opts or {}

    -- improvements vs using telescope's builtin.git_status
    -- 1. jump to selected hunk when you open the file! (on Enter)
    --    this is the main reason I made my own picker
    -- 2. previewer:
    --    1. show entire file (vs git_status which just shows the diff)
    --       syntax highlighted too (color)
    --    2. scroll to + highlight hunk
    --
    --    basically a picker previewer like I setup for my semantic_grep picker
    -- 3. extensible to new pickers:
    --    - added `git diff` vs `git diff --staged` already
    --      PRN get entire file using git show? not sure this is ever needed for `git diff` (nor `--staged`)
    --         but using it here too might make a unified platform for other scenarios
    --    TODO any issues with showing file from history? will probably need to use git to get the file
    --    FYI refactor this to have location providers:
    --    - i.e. git diff hunks, staged hunks, stash list, stash show, git log, etc...
    --    - each location result can have:
    --      - preview contents (or function to lazy load) - w/e shows on right in picker
    --        can show worktree files, dirs
    --        can show a file using `git show` as of a commit
    --      - action function when selected (as well as any other actions I define)
    --        can open a file in worktree (i.e. for git diff)
    --        can open a buffer w/ old version of file (not in worktree) via git show
    --        can open a sub-picker (i.e. git stash list => pick stash ref => git stash show the hunks/files as of the commit)


    -- FYI GH issue (for builtin.git_status picker) closed as not planned:
    --   https://github.com/nvim-telescope/telescope.nvim/issues/3341
    --   seems like there's no interest in jumping to the hunk you selected in the telescope picker
    --   very strange IMO
    --   why would I want to pick a changed hunk (could even be multiple in a file)
    --     and then jump to the start of the file?
    --     only to then have to step through hunks (if I have gitsigns)
    --     until I land on the hunk I already selected?

    local rev = opts.rev
    local cmd
    if rev then
        -- show the diff introduced by a specific commit (used by g1/g2/g3)
        cmd = { "git", "show", "--pretty=format:", "--unified=0", "--no-color", rev }
    else
        cmd = { "git", "diff", "--unified=0", "--no-color" }
        if opts.staged then
            table.insert(cmd, "--staged")
        end
    end
    log:warn(cmd)

    local output = vim.fn.systemlist(cmd)


    if vim.v.shell_error ~= 0 then
        vim.notify("git diff failed", vim.log.levels.ERROR)
        return
    end

    local hunks = parse_diff(output)

    local prompt_title = "Git Hunks"
    if rev then
        prompt_title = "Git Hunks " .. rev
    elseif opts.staged then
        prompt_title = "Git Hunks (staged)"
    end

    pickers.new(opts, {
        prompt_title = prompt_title,

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

                local preview_path = preview_filepath(rev, entry.filename)
                previewers.buffer_previewer_maker(
                    preview_path,
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
        --  and gds for staged... I use both of these as fish abbrs too
        vim.notify("Use <leader>gd instead of <leader>gst for git hunks", vim.log.levels.INFO)
    end)
    vim.keymap.set("n", "<leader>gd", M.git_hunks)
    vim.keymap.set("n", "<leader>gds", function()
        M.git_hunks({ staged = true })
    end)
    -- show the changes introduced by the last few commits
    vim.keymap.set("n", "<leader>g1", function()
        M.git_hunks({ rev = "HEAD" })
    end)
    vim.keymap.set("n", "<leader>g2", function()
        M.git_hunks({ rev = "HEAD~1" })
    end)
    vim.keymap.set("n", "<leader>g3", function()
        M.git_hunks({ rev = "HEAD~2" })
    end)

    -- go further back without keymaps: e.g. `:GitHunks 5` or `:GitHunks HEAD~10`
    vim.api.nvim_create_user_command("GitHunks", function(command)
        local rev = command.args
        if rev:match("^%d+$") then
            rev = "HEAD~" .. rev
        end
        if rev == "" then
            rev = "HEAD"
        end
        M.git_hunks({ rev = rev })
    end, {
        nargs = "?",
        desc = "Show git hunks for a commit (default HEAD)",
        complete = function()
            local candidates = {}
            for i = 0, 9 do
                candidates[#candidates + 1] = "HEAD~" .. i
            end
            return candidates
        end,
    })
end

return M
