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


-- FEELS MUCH BETTER:
--  switch to terminal buffer => starts in terminal mode (not normal mode which is default)
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "term://*",
    callback = function()
        vim.cmd("startinsert")
    end
})

-- PRN later... look into using OSC codes
--autocmd for TermRequest
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
            local common = require("iron.fts.common")
            local ll = require("iron.lowlevel")

            function my_repl()
                local meta = vim.b[0].repl

                if not meta or not ll.repl_exists(meta) then
                    ft = ft or ll.get_buffer_ft(0)
                    meta = ll.get(ft)
                end

                if not ll.repl_exists(meta) then
                    return
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
                meta = my_repl()
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
            -- ok I ❤️  THESE:
            vim.keymap.set('n', '<leader>icl', function()
                my_clear()
                iron.send_line()
            end)
            vim.keymap.set('n', '<leader>icb', function()
                my_clear()
                iron.send_code_block()
            end)
            vim.keymap.set('n', '<leader>icp', function()
                my_clear()
                iron.send_paragraph({})
            end)
            vim.keymap.set('n', '<leader>icf', function()
                my_clear()
                iron.send_file()
            end)

            iron.setup {
                config = {
                    scratch_repl = true, -- discard repls?
                    -- TODO how can I turn of close prompt or not have to switch to repl to confirm yes/no... and why not just have a "restore" instead so no confirm to close?
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
                            -- format = common.bracketed_paste_python, -- use unadulterated formatter
                            format = function(lines, extras)
                                result = common.bracketed_paste_python(lines, extras)
                                -- remove lines that only contain a comment
                                filtered = vim.tbl_filter(function(line) return not string.match(line, "^%s*#") end, result)
                                return filtered
                            end,
                            block_deviders = { "# %%", "#%%" }, -- TODO TRY BLOCK DIVIDERS with which motion?

                            -- use iterm to split pane, not sure this does what ChatGPT thought it would do :)... this just runs iterm in a nested terminal window
                            -- command = { "osascript", "-e", [[tell app "iTerm" to tell the current window to create tab with default profile]] },
                            -- format = require("iron.fts.common").bracketed_paste,
                        }
                    },
                    repl_filetype = function(bufnr, ft)
                        -- set repl filetype (to language used)
                        return ft
                    end,
                    repl_open_cmd = view.split.vertical("50%"),
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
                    send_until_cursor = "<space>isc", -- run file to cursor
                    --
                    send_code_block = "<space>isb", -- *** OMG YES, works with block_deviders (above)
                    send_code_block_and_move = "<space>isn", -- also moves to next cell
                    --
                    -- send_mark = "<space>ism",
                    -- mark_motion = "<space>imc",
                    -- mark_visual = "<space>imc",
                    -- remove_mark = "<space>imd",
                    --
                    cr = "<space>is<cr>",
                    interrupt = "<space>isi",
                    exit = "<space>isq",
                    --
                    clear = "<space>icc", -- use icc so it immediately executes, if I left it at ic it hangs while waiting for any three char combos
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
