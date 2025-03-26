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
            local iron = require("iron.core")
            local view = require("iron.view")
            local config = require("iron.config")
            local ll = require("iron.lowlevel")

            function get_or_open_repl()
                -- FYI based on https://github.com/g0t4/iron.nvim/blob/d8c2869/lua/iron/core.lua#L254-L274
                local meta = vim.b[0].repl

                if not meta or not ll.repl_exists(meta) then
                    ft = ft or ll.get_buffer_ft(0)
                    -- if data == nil then return end
                    meta = ll.get(ft)
                end

                -- If the repl doesn't exist, it will be created
                if not ll.repl_exists(meta) then
                    meta = iron.repl_for(ft)
                end

                return meta
            end

            function my_clear()
                -- STATUS:
                -- - btw, this works for ipython
                -- - works with lua to stop the empty scrollback lines after ctrl-l
                -- - buggy for fish shell is all (so far that I have found)
                --
                -- clear scrollback somehow clears in lua (kinda, the lines go away but empty lines still are there in scrollback)
                -- for almost all other shells (i.e. ipython, fish) the scrollback is still there entirely
                iron.clear_repl()
                -- TODO do I not wanna open it if its closed, when it comes to clear commands?
                meta = get_or_open_repl()
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
            end

            -- clear and then send
            function clearThen(func)
                return function()
                    my_clear()
                    func()
                end
            end

            -- clear and run top block (to this point) THEN run current block (selected text in visual mode)
            function runTopBlockThenThisBlock()
                my_clear()
                local meta = get_or_open_repl()
                if not meta then return end

                -- PRN add check for blocks before running whole file?
                -- FOR NOW assume user knows that there are blocks and just run it
                --    that means the whole file runs (twice) if there are no blocks
                --    or if cursor in top block already, it runs that twice then

                local cursor_position = vim.api.nvim_win_get_cursor(0)

                -- move cursor to top of file
                vim.cmd("norm gg")
                iron.send_code_block()
                my_clear()

                vim.api.nvim_win_set_cursor(0, cursor_position)

                -- run block user wanted run
                iron.send_code_block()
            end

            -- ok I ❤️  THESE:
            vim.keymap.set('n', '<leader>icm', clearThen(function() iron.run_motion("send_motion") end), { desc = 'clear => send motion' })
            vim.keymap.set('v', '<leader>icv', clearThen(function() iron.send(nil, iron.mark_visual()) end), { desc = 'clear => send visual' })
            vim.keymap.set('n', '<leader>icf', clearThen(iron.send_file), { desc = 'clear => send file' })
            vim.keymap.set('n', '<leader>icl', clearThen(iron.send_line), { desc = 'clear => send line' })
            vim.keymap.set('n', '<leader>icp', clearThen(iron.send_paragraph), { desc = 'clear => send paragraph' })
            -- reminder, with `isp` iron.nvim uses `iron.send_paragraph({})` ... do I need the ({}) for any reason? so far no issues
            vim.keymap.set('n', '<leader>icb', clearThen(iron.send_code_block), { desc = 'clear => send block' })
            vim.keymap.set('n', '<leader>icn', clearThen(function() iron.send_code_block(true) end), { desc = 'clear => send block and move to next block' })
            vim.keymap.set('n', '<leader>ict', clearThen(runTopBlockThenThisBlock), { desc = 'clear => run top block then current block' })
            vim.keymap.set('n', '<leader>icc', my_clear, { desc = 'clear' })

            iron.setup {
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
                            block_deviders = { "# %%", "#%%" },
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
                    send_mark = "<space>ims", -- send marked code
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
