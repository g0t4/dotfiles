-- TERMINAL CONFIG

-- ** esc to normal mode
-- one reason this may be a problem is using esc keymaps (binds) in fish shell (etc)
--    one workaround is to switch to using alt+* so alt effectively becomes my meta key instead of esc (I think this will work out just fine)
--     ya know, when I am using a terminal, a primary reason to exit terminal mode is just to switch panes... why not just click with mouse in that one case?
--       would this obviate the need for esc to exit to normal mode?
--       or should I suck it up and learn to use <C-\><C-n> which is not the end of the world either? or remap it?
vim.keymap.set('t', '<esc>', "<C-\\><C-n>", { desc = 'exit terminal' }) -- that way Esc in terminal mode allows exiting to normal mode, I hate doing ctrl-\,ctrl-n to do that


-- *** switch windows (leave terminal window)
-- TODO figure out if I wanna do smth besides click out of a terminal...
--   honestly with iron.nvim I think I shouldn't need to spend much time (if any) in the terminal
--   I should be sending commands is about it from scripts that I always create in files anyways!
--   that said when building cmds, tab completion in fish shell is important
--     yes I get LSP completions but it doesn't feel the same (can it?)
-- for _, arrow in ipairs({ "right", "left", "up", "down" }) do
--     -- <Cmd>wincmd == one keymap for both modes (n/i) + preserve mode after switch
--     --   also, this adds 4 fewer keymaps overall, so when I use :map to list them all, I see fewer
--     local dir = arrow == "left" and "h" or arrow == "right" and "l" or arrow == "up" and "k" or "j"
--     -- disable "i" insert mode b/c I use alt+right for accept next work in suggestions
--     -- vim.keymap.set({ "t" }, "<C-w><" .. arrow .. ">", "<Cmd>wincmd " .. dir .. "<CR>")
--     -- CRAP Ctrl-W is not good to hijack :) as i use it to clear a word back
-- end


-- ** pros/cons of terminal in nvim
-- pros:
-- - sending lines and executing lines right out of a script so I don't have to switch tabs/panes as I build out scripts
-- - I like path completion inside of nvim! it works well too (can see the coc completion results for actual files) => fish shell tab complete is great too, but this is like icing on top of what fish does
-- cons:
-- - scrollback clearing is problematic, but can likely be fixed with a bit more keymap customizations
-- - accidentally forget and use Cmd+K, which I do often enough for just nvim/vim itself :)


-- FEELS MUCH BETTER:
--  switch to terminal buffer => starts in terminal mode (not normal mode which is default)
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "term://*",
    callback = function()
        vim.cmd("startinsert")
    end
})

-- PRN later... look into using OSC codes
-- autocmd for TermRequest
-- vim.api.nvim_create_autocmd({ "TermRequest" }, {
--     -- https://github.com/neovim/neovim/issues/4413
--     callback = function(evt)
--         -- i.e. handle current dir changes (i.e. could use to show nvim-tree for that dir)
--         --   data = "\27]1337;CurrentDir=/path/to/foo",
--         print("termrequest: ")
--         print("termrequest: ", vim.inspect(evt))
--     end
-- })

return {


    -- *** JUPYTER / REPLs ***
    --  HONESTLY, I just wanna be able to run python code like a notebook but I hate the NB interface (esp VSCode)..
    --    want to keep a session open
    --    - ** not re-run a script every time I change it
    --    - saves load times (esp w/ datasets/models that are huge)
    --    - * REPL integration so I don't have to copy/paste
    --      - ipython REPL (color / tab completion)
    --    - maybe: cell deliniation
    --      - actually, just an easy selection mechanism (maybe just use vim motions)
    --      - maybe setup a shortcut <leader>c or w/e and have it grep for a start/end marker I pick? selects between cell border comments
    --
    --  - *first, try w/o jupyter notebook?
    --     this will be superior in some ways b/c I can run adhoc code too (in the REPL) and don't have to put it in a cell for quick testing
    --     also, REPL route supports other languages  (conjure, iron.nvim)
    --
    -- CONSIDERING:
    --   REPL integration:
    --   "Olical/conjure"
    --   "Vigemus/iron.nvim"
    --
    --   JUPYTER notebook support:
    --   "kiyoon/jupynium.nvim", -- probably best option if I wanna try full jupyter integration (drives a separate, synchronized nb instance)
    --   "jupyter-vim/jupyter-vim"
    --
    -- *** WIP iron.nvim ***
    {
        -- FULLY EVALUATE iron.nvim before touching anything else
        --  Likes => all the keymaps make 100% sense, esp `isb` for block (cell deliniator)
        --    multiple languages (i.e. python, lua, shell)
        --  Actually using terminal windows makes sense as most of the time I am not gonna be using that terminal, just sending commands with keymaps
        --
        -- "Vigemus/iron.nvim",
        "g0t4/iron.nvim",
        branch = "fix-clear-repl",
        -- dir = "~/repos/github/g0t4/iron.nvim",
        enabled = true,
        event = { "BufReadPre", "BufNewFile" },

        config = function()
            local core = require("iron.core")
            local ll = require("iron.lowlevel")

            function ensure_open()
                -- FYI based on https://github.com/g0t4/iron.nvim/blob/d8c2869/lua/iron/core.lua#L254-L274
                local meta = vim.b[0].repl

                if not meta or not ll.repl_exists(meta) then
                    ft = ft or ll.get_buffer_ft(0)
                    -- if data == nil then return end
                    meta = ll.get(ft)
                end

                -- If the repl doesn't exist, it will be created
                if not ll.repl_exists(meta) then
                    meta = core.repl_for(ft)
                end

                return meta
            end

            function ensure_open_and_cleared()
                -- STATUS:
                -- - btw, this works for ipython
                -- - works with lua to stop the empty scrollback lines after ctrl-l
                -- - buggy for fish shell is all (so far that I have found)
                --
                -- clear scrollback somehow clears in lua (kinda, the lines go away but empty lines still are there in scrollback)
                -- for almost all other shells (i.e. ipython, fish) the scrollback is still there entirely
                core.clear_repl()
                -- TODO do I not wanna open it if its closed, when it comes to clear commands?
                local meta = ensure_open()
                if meta == nil then
                    return
                end

                -- vim.fn.feedkeys("^L", 'n') -- if wanna send self, need to switch buffers first vim.api.nvim_set_current_buf(bufnr) + vim.defer_fn if needed
                -- DOES NOT FULLY WORK
                --  interesting when I use this myself in fish terminal buffer it does work
                --  focus and go into terminal mode
                --  Ctrl-L
                --  :set scrollback=1
                --  :set scrollback=100000
                --  FOR NOW try not to rely on too much scrolling backwards is likely best bet

                local sb = vim.bo[meta.bufnr].scrollback
                -- hack to truncate scrollback, works in ipython, half way clears in fish
                vim.bo[meta.bufnr].scrollback = 1
                vim.bo[meta.bufnr].scrollback = sb

                return meta
            end

            function clear_then(func)
                return function()
                    ensure_open_and_cleared()
                    func()
                end
            end

            function send_top_block_then_current_block()
                -- previously, I would just run whole file `isf` then `icb` for current block...
                --  this collapses that into one command and hopefully obviates running code I don't care about if I can make top block comprise most if not all init and otherwise have each block be standalone
                --  I could come up with more conventions for related blocks... but lets KISS for now

                local meta = ensure_open_and_cleared()
                if not meta then return end

                -- PRN add check for blocks before running whole file?
                -- FOR NOW assume user knows that there are blocks and just run it
                --    that means the whole file runs (twice) if there are no blocks
                --    or if cursor in top block already, it runs that twice then

                local cursor_position = vim.api.nvim_win_get_cursor(0)

                -- move cursor to top of file
                vim.cmd("norm gg")
                -- FYI if this is jarring to jump around, then lets extract logic to get contents of a given block based on a line #
                --     use:   https://github.com/g0t4/iron.nvim/blob/d8c2869/lua/iron/core.lua#L517-L547
                core.send_code_block()
                ensure_open_and_cleared()

                vim.api.nvim_win_set_cursor(0, cursor_position)

                -- run block user wanted run
                core.send_code_block()
            end

            -- ok I ❤️  THESE:
            vim.keymap.set('n', '<leader>icm', clear_then(function() core.run_motion("send_motion") end), { desc = 'clear => send motion' })
            vim.keymap.set('v', '<leader>icv', clear_then(function() core.send(nil, core.mark_visual()) end), { desc = 'clear => send visual' })
            vim.keymap.set('n', '<leader>icf', clear_then(core.send_file), { desc = 'clear => send file' })
            vim.keymap.set('n', '<leader>icl', clear_then(core.send_line), { desc = 'clear => send line' })
            vim.keymap.set('n', '<leader>icp', clear_then(core.send_paragraph), { desc = 'clear => send paragraph' })
            -- reminder, with `isp` iron.nvim uses `iron.send_paragraph({})` ... do I need the ({}) for any reason? so far no issues
            vim.keymap.set('n', '<leader>icb', clear_then(core.send_code_block), { desc = 'clear => send block' })
            vim.keymap.set('n', '<leader>icn', clear_then(function() core.send_code_block(true) end), { desc = 'clear => send block and move to next block' })
            vim.keymap.set('n', '<leader>ict', clear_then(send_top_block_then_current_block), { desc = 'clear => run top block then current block' })
            vim.keymap.set('n', '<leader>ist', send_top_block_then_current_block, { desc = 'run top block then current block' })
            vim.keymap.set('n', '<leader>icc', ensure_open_and_cleared, { desc = 'clear' })

            function current_line_is_blank()
                local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
                local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
                -- print("current line: '" .. current_line .. "'")
                return current_line:match("^%s*$")
            end

            function is_line_before_blank_or_first_in_file()
                local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
                if row == 1 then
                    -- edge case, could go either way, I don't intend to put delimiter at start or end of file so not that important in this case
                    return true
                end
                local previous_line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1]
                -- print("previous line: '" .. previous_line .. "'")
                return previous_line:match("^%s*$")
            end

            vim.keymap.set('n', '<leader>ij', function()
                -- move down to next cell
                local start_line, _ = unpack(vim.api.nvim_win_get_cursor(0))
                -- find first line below me that has cell block devider
                -- TODO check for all deviders
                -- PRN is there already logic in iron.nvim that I could reuse for this? (it has exec block and go to next action)
                local cell_block_devider = require("iron.config").repl_definition[vim.bo.filetype].block_deviders[1]
                -- does not include cursor line (that way if on a cell's devider you will jump to next cell not "current" cell
                local all_lines_below_cursor_line = vim.api.nvim_buf_get_lines(0, start_line, 10000, false)
                for lines_below, line in ipairs(all_lines_below_cursor_line) do
                    if string.match(line, cell_block_devider) then
                        -- +1 => line after devider
                        local block_line_number = start_line + lines_below + 1
                        print("block_line_number: " .. (block_line_number or 'none'))
                        if lines_below == #all_lines_below_cursor_line then
                            -- if the last line is a cell devider then jump to it instead of line after
                            block_line_number = block_line_number - 1
                        end
                        vim.api.nvim_win_set_cursor(0, { block_line_number, 1 })
                        break
                    end
                end
            end, { desc = 'iron' })
            vim.keymap.set('n', '<leader>ik', function()
                -- move up to previous cell
                local start_line, _ = unpack(vim.api.nvim_win_get_cursor(0))
                local cell_block_devider = require("iron.config").repl_definition[vim.bo.filetype].block_deviders[1]
                local all_lines_above_cursor_line = vim.api.nvim_buf_get_lines(0, 1, start_line - 1, false)
                local reversed = vim.fn.reverse(all_lines_above_cursor_line)
                -- print(vim.inspect(reversed))
                for lines_above, line in ipairs(reversed) do
                    if string.match(line, cell_block_devider) then
                        -- jump to end of previous cell is fine, I think that makes more sense when moving upward?
                        -- -1 => line before devider
                        local block_line_number = start_line - lines_above - 1
                        vim.api.nvim_win_set_cursor(0, { block_line_number, 1 })
                        break
                    end
                end
            end, { desc = 'iron' })


            vim.keymap.set('n', '<leader>ib', function()
                -- [i]nsert [b]lock divider
                -- TODO make this per language, use lookup based on iron config that I have for block_deviders
                if vim.bo.filetype ~= 'python' then
                    vim.notify('block divider only intended for python currently', vim.log.levels.WARN)
                end

                local use_devider = require("iron.config").repl_definition[vim.bo.filetype].block_deviders[1]
                print("use_devider: '" .. use_devider .. "'")

                if not current_line_is_blank() then
                    -- move to after/end of paragraph
                    vim.api.nvim_feedkeys("}", "n", false)

                    vim.defer_fn(function()
                        -- without defer, current line always the same original line
                        -- OR am I doing something else wrong?

                        if not current_line_is_blank() then
                            -- if last line of paragraph is last line of file, then it will need a new insert afterward
                            --  => this manifests as not being a blank line after }
                            local keys = vim.api.nvim_replace_termcodes("o<Esc>", true, false, true)
                            vim.api.nvim_feedkeys(keys, "n", false)
                        end

                        -- TODO lets just literally insert a blank line and not use o... that way if language continues a comment on o/O then it wont add second comment line (i.e. in lua, but I don't have python configured that way)
                        local keys = vim.api.nvim_replace_termcodes("o" .. use_devider .. "<CR><Esc>", true, false, true)
                        vim.api.nvim_feedkeys(keys, "n", false)
                    end, 0)
                else
                    if not is_line_before_blank_or_first_in_file() then
                        -- make sure blank line before divider
                        local keys = vim.api.nvim_replace_termcodes("o<Esc>", true, false, true)
                        vim.api.nvim_feedkeys(keys, "n", false)
                    end
                    -- TODO also, insert blank line instead of using 'o'... and actually lets use that to insert everything and then move the cursor too?
                    local keys = vim.api.nvim_replace_termcodes("i" .. use_devider .. " <CR><Esc>", true, false, true)
                    vim.api.nvim_feedkeys(keys, "n", false)
                    -- FYI b/c I use <CR> to insert a line, that ensures there is a new line after the divider
                end
            end, { desc = 'iron' })

            core.setup {
                config = {
                    scratch_repl = true, -- discard repls?
                    repl_definition = {
                        sh = {
                            -- command: either a table, or a func that returns a table
                            command = { "fish" },
                        },
                        lua = {
                            command = { "lua" },
                            -- are these not set OOB? or is it diff default for lua?
                            block_deviders = { "-- %% ", "--%%" },
                        },
                        python = {
                            -- PRN if need be, create a profile for configuring how ipython runs inside of iron.nvim (only if issues with config outside of nvim), --profile foo
                            command = { "ipython", "--no-autoindent" },
                            -- command = { "python3" },
                            -- FYI careful with bracketed_paste VS bracketed_paste_python!!!
                            -- format = require("iron.fts.common").bracketed_paste, -- for ipython?
                            -- format = require("iron.fts.common").bracketed_paste_python, -- for python3 not ipython, right?
                            format = function(lines, extras)
                                -- TLDR:
                                --   I really like cell per line which effectively auto labels each print statement! with the full chunk of code
                                --     really this is one statement per cell (i.e. functions act as wrappers)
                                --     I do not really want to label my output manually every time
                                --     bracketed_paste => runs entire selection as one chunk (so isf => all of file in one go is impossible to discren WTF is WHAT)
                                --   ONLY nice to have would be to stop on the first failing line (cell)  when running multiple lines (cells)
                                --   IF I want batched lines (not interleaved):
                                --     I can use a function which is treated as one statement/line/cell
                                --   TBH, it did take a second to get used to the interleaved code and lines but now I really, really like it
                                -- result = require("iron.fts.common").bracketed_paste(lines, extras) -- everything selected is one cell (yuck)
                                result = require("iron.fts.common").bracketed_paste_python(lines, extras) -- *** defacto is cell per line (yes)

                                --  FYI I am unsure that bracketed_paste/bracketed_paste_python differences are intended so if they "fix" the way I like it, then I should add my own version

                                -- remove lines that only contain a comment
                                -- FYI I really like this with cell per line style! b/c it makes it more compact!!!
                                filtered = vim.tbl_filter(function(line) return not string.match(line, "^%s*#") end, result)
                                return filtered
                            end,
                            block_deviders = { "#%%" }, -- "# %%" (just use one devider, can always find/replace if I need them changed)
                            -- use iterm to split pane, not sure this does what ChatGPT thought it would do :)... this just runs iterm in a nested terminal window
                            -- command = { "osascript", "-e", [[tell app "iTerm" to tell the current window to create tab with default profile]] },
                        }
                    },
                    repl_filetype = function(bufnr, ft)
                        -- set repl filetype (to language used)
                        return ft
                    end,
                    repl_open_cmd = "vertical split", -- use regular window commands
                    -- repl_open_cmd = view.split.vertical("50%"), -- DSL style... doesn't adjust with Ctrl+W,= (have to toggle close/open to fix split at 50% after font zoom change)
                    -- When repl_open_cmd is an array table, IronRepl uses first cmd:
                    -- repl_open_cmd = {
                    --   view.split.vertical.rightbelow("%40"), -- cmd_1: open a repl to the right
                    --   view.split.rightbelow("%25")  -- cmd_2: open a repl below
                    -- }
                },

                -- no keymaps by default (Amen):
                keymaps = {
                    toggle_repl = "<space>ir", -- toggles the repl open and closed.
                    -- If repl_open_command is a table, then:
                    -- toggle_repl_with_cmd_1 = "<space>rv",
                    -- toggle_repl_with_cmd_2 = "<space>rh",
                    restart_repl = "<space>iR", -- calls `IronRestart` to restart the repl

                    -- send keymaps (<leader>is prefix currently):
                    send_motion = "<space>ism", -- motion right after!
                    visual_send = "<space>isv", -- send selection
                    send_file = "<space>isf", -- *
                    send_line = "<space>isl", -- *
                    send_paragraph = "<space>isp", -- * think {}
                    send_until_cursor = "<space>isu", -- run file [u]ntil cursor
                    --
                    send_code_block = "<space>isb", -- *** OMG YES, works with block_deviders (above)
                    send_code_block_and_move = "<space>isn", -- also moves to next cell
                    --
                    mark_motion = "<space>imm", -- mark a selection use a motion
                    mark_visual = "<space>imv", -- set marks based on visual selection
                    remove_mark = "<space>imd", -- remove marks
                    send_mark = "<space>imr", -- ([r]e)send marked code (any other send keymap will mark the range so it can be repeated too with this)
                    --
                    cr = "<space>is<cr>",
                    interrupt = "<space>isi",
                    exit = "<space>isq",
                    --
                    -- clear = "<space>icc", -- map to my_clear above to open if not already
                    -- FYI fixed clear when using bracketed_paste_python:
                    --   https://github.com/g0t4/iron.nvim/blob/3860d7f/lua/iron/core.lua#L167
                    --   otherwise formatter replaces FF with CR b/c it seems FF as empty line
                },
                highlight = {
                    -- can set hl group to control style too
                    italic = true -- IIUC is for last line run
                },
                ignore_blank_lines = true, -- when sending visual select lines, IIAC to not sumbmit extra prompt lines before/after/between sent commands
            }
        end

    },


    -- *** TESTING ***
    -- TODO try testing, instead of / in addition to Plenary
    -- {
    --     "nvim-neotest/neotest",
    -- },

    {
        -- FYI use `:Notifications` to see history of notifications
        "rcarriga/nvim-notify",
        config = function()
            -- FYI I will probably hate this with hardline... maybe turn off hardline warns then?
            vim.notify = require("notify") -- route all notifications through this (plugins can use vim.notify none the wiser)
            require("notify").setup({
                -- stages = "fade",
                --
                -- wtf... turning on wrapped/wrapped-default ignores newlines \n ... UGH
                --    without this, long strings just run off the screen..
                --    why can't I have new line + wrap... and why can't I have wrap based on width of screen (set max to screen width and not force a hard coded amount... UGH)
                --    can set render on a per notify call basis, but it doesn't use max_width on per notify call so its a mess of the default max_width of like 20
                --    OK for now just pass "wrapped-compact" on per notify call and that looks good enough (still has new line issue but whatever)
                -- render = "wrapped-default",
                -- max_width = 80,
            })
        end,
    },

    -- {
    --     "https://github.com/folke/noice.nvim",
    --     config = function()
    --         require("noice").setup({
    --         })
    --     end,
    --     dependencies = {
    --         "rcarriga/nvim-notify",
    --         "MunifTanjim/nui.nvim",
    --     },
    --     -- TODO TRY THIS
    --     -- command output in regular buffer!!! YES?! i.e. `:highlight` or `:nmap` => not the stupid output pager thingy you cannot leave open
    --     -- many others, not sure I want all mods
    -- },

}
