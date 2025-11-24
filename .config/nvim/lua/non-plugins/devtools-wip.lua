--
-- * think of this as devtools for neovim
-- FYI move stable ideas into devtools.nvim repo

local ENABLE_CUSTOM_ABBRS_IN_CMDLINE = false -- *** toggle on/off
if ENABLE_CUSTOM_ABBRS_IN_CMDLINE then
    local abbrevs = {
        i = {
            -- btw = "by the way",
            idk = "I don't know",
        },
        c = {
            -- lnvim = "Dump vim.api.nvim_",

            -- wls = "Dump vim.api.nvim_list_wins()",
            -- bls = "Dump vim.api.nvim_list_bufs()",
            -- bls = "buffers",
            -- tls = "tabs",
        }
    }

    for mode, defs in pairs(abbrevs) do
        for lhs, rhs in pairs(defs) do
            vim.cmd(string.format("%sabbrev %s %s", mode, lhs, rhs))
        end
    end

    -- * space-less expansions (abbreviations)
    -- FYI I am actually not convinced anymore that this is the best idea... i.e. when I try to type `nmap` I often get `nmapp` ...
    local config = {
        prefixes = {
            -- FYI nvim-cmp already setup to show completions as you type
            --   so no need for <TAB> on end if using nvim-cmp
            --
            -- a regular abbreviation doesn't have aa way to not include the character after that triggered the expansion (i.e. space)
            -- TODO do I like the " " or not...  expand before it instead? or does it feel more natural to expand/"remove" it
            --    both are kinda odd
            --    see what feels right
            --    try each style for a few days and see how it feels
            --
            -- FYI config PLEBS... you want "lua <vim>.<TAB>" ... if you can't handle my :Dump
            ["dvim "] = "Dump vim.",
            ["dts "] = "Dump vim.treesitter.",
            ["=ts "] = "= vim.treesitter.", -- buggy w/o <C-S-U> fix below
            ["dapi "] = "Dump vim.api.",
            ["dfn "] = "Dump vim.fn.",
            -- ["nvim"] = "Dump vim.api.nvim_", -- tab to auto open completion!
            ["nvim "] = "Dump vim.api.nvim_", -- tab to auto open completion!
            ["nma"] = "nmap", -- for now just setup to type the p for me... since I need nml for leader keys
            ["nml"] = "nmap <leader>",
            ["ima"] = "imap",
            ["iml"] = "imap <leader>",
            ["vma"] = "vmap",
            ["vml"] = "vmap <leader>",

            -- FYI cannot namespace... they cannot collide at all... without a mechaism to pause and yeah not sure I wanna have that
            -- ["nvimw"] = "Dump vim.api.nvim_win_", -- IOTW nvim here would already expand before I type the w and so
            --     I get "Dump vim.api.nvim_w" ... but that reminds me thats fine by me! I can type the W
            -- ["nvimb"] = "Dump vim.api.nvim_buf_",
        }
    }

    vim.api.nvim_create_autocmd("CmdlineChanged", {
        pattern = ":",
        callback = function()
            local line = vim.fn.getcmdline()
            for prefix, expansion in pairs(config.prefixes) do
                if line:match("^" .. prefix .. "$") then
                    vim.schedule(function()
                        -- FYI! this is a good demo of my message buffer dump tool
                        --   handlers would otherwise require to open messages after every event you want to test
                        --   notify is an alternative but clutters up the screen
                        -- dump.open_append("activated: " .. prefix .. " -> " .. expansion)
                        -- nvim-cmp has <C-u> for smth...

                        -- anyways, I need capital U so if I add shift this seems to work fine
                        -- w/o -S then I get <C-U> activating weird behavior (loops on activating completions w/ nvim-cmp)
                        --    I picked -S... b/c IIUC <C-U>(capital U) should remove all chars from cursor, back to the start of the line
                        --    only happens on some mappings (see above)
                        -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-S-U>" .. expansion, true, false, true))
                        -- FYI if setcmdline works, lets get rid of feedkeys

                        -- FYI alternative... just set the damn commandline
                        vim.fn.setcmdline(expansion)
                        -- PRN could add feeding keys if needed, but I don't need that right now
                        -- and, nvim-cmp still shows completions after setcmdline!
                    end)
                    break
                end
            end
        end,
    })
end

local ENABLE_TEST_CMDLINE_SELECTION_SUMMARY_TEXT = true -- *** toggle on/off
if ENABLE_TEST_CMDLINE_SELECTION_SUMMARY_TEXT then
    -- *** change messages shown when selecting text
    -- default shows #chars if in v visual model and only selecting text on one line
    --    if multiple lines it shows # lines even though its visual charwise
    -- V (linewise visual) shows # lines always
    -- AND, all of this is confusing b/c it only shows a # and no units... so no "lines" or "chars" shown

    local GetPos = require("ask-openai.helpers.wrap_getpos") -- TODO move to devtools.nvim once I am happy with GetPos, and make this an example configuration

    -- TODO! before you enable this, make sure you understand what will be missing...
    -- TODO! otherwise, you will forget that you did this and pooch smth important :)

    --- FYI! I really like this (showing better summary of what is selected at bottom of screen)! but I need to revisit it later (I am already 3 deep in the distractions stack tonight)

    local function custom_show_mode_message()
        local mode = vim.fn.mode()
        local sel = GetPos.current_selection()
        -- TODO move line count to GetPos return type
        local line_count = sel.end_line_base1 - sel.start_line_base1 + 1
        if mode == 'V' then
            return string.format("Visual (linewise) - Selected %d lines", line_count)
        elseif mode == 'v' then
            if sel.start_line_base1 ~= sel.end_line_base1 then
                return string.format("visual (charwise) - Selected across %d lines", line_count)
            else
                local char_count = sel.end_col_base1 - sel.start_col_base1 + 1
                return string.format("visual (charwise) - Selected %d chars (on a single line)", char_count)
            end
        else
            -- TODO other cases?
            -- Visual Block mode? normally shows 2x3 (lines x cols)
            -- Insert mode shows -- INSERT -- (nothing else AFAICT)
            -- Save messages?
            -- last command ran?
        end
        -- FYI could show "Last Selection 10 lines"? outside of visual modes? i.e. to know when I accidentally changed modes
        return ""
    end

    vim.cmd("set noshowcmd ")
    vim.cmd("set noshowmode ") -- hide -- * --
    -- show mode shows -- VISUAL -- or -- VISUAL LINE -- or -- INSERT --
    vim.cmd("set cmdheight=3 ") -- use this for testing if smth else is "interfering" ... i.e. if showmode is on
    -- FYI leave cmdheight absurdly high for now so I notice it and turn off this summary when I am done for the day


    vim.api.nvim_create_autocmd({ "ModeChanged" }, {
        pattern = "*:V",
        callback = function()
            vim.opt.showcmd = false
            vim.api.nvim_echo({ { custom_show_mode_message(), "Normal" } }, false, {})
            -- by the way if you leave showmode on.. and you enter V mode (first line is selected) but it won't show the selection if you are using nvim_echo... it will show it once you expand to another line above/below
        end,
    })

    vim.api.nvim_create_autocmd({ "ModeChanged" }, {
        pattern = "V:*",
        callback = function()
            vim.opt.showcmd = true
            vim.api.nvim_echo({ { "", "Normal" } }, false, {})
        end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        pattern = "*",
        callback = function()
            -- if vim.fn.mode():match("v") or vim.fn.mode():match("V") then
            -- vim.opt.showcmd = false
            vim.api.nvim_echo({ { custom_show_mode_message(), "Normal" } }, false, {})
            -- end
        end,
    })
end
