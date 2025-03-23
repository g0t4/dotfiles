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
        --  Unsure => terminal windows, thus far I have been apprehensive and prefer iterm panes, but I can give it a try and see
        --   PRN, add motion or keymap to select a "cell"
        "Vigemus/iron.nvim",
        config = function()
            local iron = require("iron.core")
            local view = require("iron.view")
            local common = require("iron.fts.common")

            -- ok yeah, I like this... if causes issues I can readdress it later... also should move this to a terminal config section not just for iron.nvim
            vim.keymap.set('t', '<esc>', "<C-\\><C-n>", { desc = 'exit terminal' }) -- that way Esc in terminal mode allows exiting to normal mode, I hate doing ctrl-\,ctrl-n to do that

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
                            command = { "ipython", "--no-autoindent" },
                            -- command = { "python3" },
                            format = common.bracketed_paste_python,
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
                    send_motion = "<space>isc", -- motion right after!
                    visual_send = "<space>isc", -- send selection
                    send_file = "<space>isf", -- *
                    send_line = "<space>isl", -- *
                    send_paragraph = "<space>isp", -- * think {}
                    send_until_cursor = "<space>isu", -- run file to cursor
                    --
                    send_code_block = "<space>isb", -- *** OMG YES, works with block_deviders (above)
                    send_code_block_and_move = "<space>isn", -- also moves to next cell
                    --
                    send_mark = "<space>ism",
                    mark_motion = "<space>imc",
                    mark_visual = "<space>imc",
                    remove_mark = "<space>imd",
                    cr = "<space>is<cr>",
                    interrupt = "<space>isi",
                    exit = "<space>isq",
                    clear = "<space>ic", -- why isn't this clearing? just submits prompt
                    -- btw, if I change to terminal, go into insert mode I can use ctrl+l to clear it
                    --   maybe I should setup terminals so ctrl+l always clears (doesn't open nvim-tree)?
                    --   though if I really start using builtin terminal then maybe I will want ctrl-L to open to PWD?
                    --   btw, what is the insert mode for a terminal buffer?
                    --      right now I can't exit this terminal insert mode... only enter it with `i`
                    --      also doesn't show blue like regular buffer in status bar
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
