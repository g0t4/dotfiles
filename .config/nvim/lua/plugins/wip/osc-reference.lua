local messages = require("devtools.messages")
--

-- FYI ^[ == \x1b

-- TODO do I have old code setting 133;A/B using fish_prompt_mark/end ? and is that still needed in fish 4?
--   certainly not causing issues but I thought fish4 has it baked in now
--   probaly leave it for now b/c some envs I still use fish 3.7 (i.e. f*#$%R ubunut/debian)

-- KEEP IN MIND this is sevearl things at play... iterm shell integration is one part
--    as the prompt is redrawn (even if no cmd submitted like with alt+left/right) the prompt is still redrawn

-- *** OSC for cdless dir change (using fish alt+left/right to move left/right and redraw prompt)
-- ^[]1337;SetUserVar=split_path=L1VzZXJzL3dlc2RlbW9zL3JlcG9zL2dpdGh1Yi9nMHQ0L2RvdGZpbGVz
-- ^[]7;file://mbp21/Users/wesdemos/repos/github/g0t4/dotfiles
-- ^[]133;A;special_key=1
-- ^[]133;D;0
-- ^[]1337;RemoteHost=wesdemos@mbp21
-- ^[]1337;CurrentDir=/Users/wesdemos/repos/github/g0t4
-- ^[]1337;SetUserVar=ask_shell=ZmlzaA==
-- ^[]1337;SetUserVar=ask_os=RGFyd2lu
-- ^[]133;A
-- ^[]133;B
-- ^[]133;A;special_key=1
-- ^[]133;D;0
-- ^[]1337;RemoteHost=wesdemos@mbp21
-- ^[]1337;CurrentDir=/Users/wesdemos/repos/github/g0t4/dotfiles
-- ^[]1337;SetUserVar=ask_shell=ZmlzaA==
-- ^[]1337;SetUserVar=ask_os=RGFyd2lu
-- ^[]133;A
-- ^[]133;B


-- *** OSC REF for cd command to new dir too
-- ^[]133;C
-- ^[]133;C;
-- ^[]133;
-- ^[]1337;SetUserVar=split_path=L1VzZXJzL3dlc2RlbW9zL3JlcG9zL2dpdGh1Yi9nMHQ0
-- ^[]7;file://mbp21/Users/wesdemos/repos/github/g0t4
-- ^[]133;D;0
-- ^[]133;A;special_key=1
-- ^[]133;D;0
-- ^[]1337;RemoteHost=wesdemos@mbp21
-- ^[]1337;CurrentDir=/Users/wesdemos/repos/github/g0t4
-- ^[]1337;SetUserVar=ask_shell=ZmlzaA==
-- ^[]1337;SetUserVar=ask_os=RGFyd2lu
-- ^[]133;A
-- ^[]133;B

-- I used this to figure out how to grab command output in REPL using tmp file, then wait for command to complete 133;D

-- *** OSC reference, keep this somewhere I can easily find it
--   https://iterm2.com/documentation-escape-codes.html
--   fish shell in v4 supports OSC 133 codes (A/B/C/D AFAICT, maybe not C actually...)
--   iterm will send others like 1337 for user variables and CurrentDir
--
-- Here is a capture I recorded with iTerm (w/ shell integration) + fish shell
--   TReq is what I printed on each TermRequest event
--
-- :mess clear
-- in terminal:
--   sleep 10<Enter>
--
-- TReq ^[]133;C
-- TReq ^[]133;C;
-- TReq ^[]133;
--
-- :echom '--------' # I ran this while sleep was still running in terminal
-- --------
-- # AFTER SLEEP FINISHES:
--
-- TReq ^[]133;D;0
-- TReq ^[]133;A;special_key=1
-- TReq ^[]133;D;0
-- TReq ^[]1337;RemoteHost=wesdemos@mbp21
-- TReq ^[]1337;CurrentDir=/Users/wesdemos/repos/github/g0t4/dotfiles
-- TReq ^[]1337;SetUserVar=ask_shell=ZmlzaA==
-- TReq ^[]1337;SetUserVar=ask_os=RGFyd2lu
-- TReq ^[]133;A
-- TReq ^[]133;B
--
vim.api.nvim_create_autocmd({ 'TermRequest' }, {
    desc = 'Handles OSC 7 dir change requests',
    callback = function(ev)
        print("TReq", vim.v.termrequest)
        -- messages.ensure_open() - even if I manually open the messages buffer... still failing
        -- FYI something is buggy about capturing OSC codes, seems like it might have to do with switching to the messages window and scrolling down maybe?
        --  not surprising given the messages buffer uses a terminal buffer too (and I have those setup to auto enter on switch, IIRC)
        --
        -- Error detected while processing TermRequest Autocommands for "*":
        -- Error executing lua callback: TermRequest Autocommands for "*": Vim(normal):Can't re-enter normal mode from terminal mode
        -- stack traceback:
        --         [C]: in function 'win_execute'
        --         ...epos/github/g0t4/devtools.nvim/lua/devtools/messages.lua:231: in function 'dump_background'
        --         ...epos/github/g0t4/devtools.nvim/lua/devtools/messages.lua:257: in function 'append'
        --         .../wesdemos/.config/nvim/lua/plugins/wip/osc-reference.lua:91: in function <.../wesdemos/.config/nvim/lua/plugins/wip/osc-reference.lua:84>       --
        --

        if string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;A' then
            messages.append("  prompt_start A")
        elseif string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;B' then
            messages.append('  ??? B')
        elseif string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;C' then
            messages.append('  command_start C')
            -- COMMAND started
        elseif string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;D' then
            messages.append('  command_end D')
            -- COMMAND finished
        else
            messages.append('  ???', tostring(vim.v.termrequest))
            print(tostring(vim.v.termrequest))
        end

        -- fodder from vim docs examples to cd on dir change in terminal
        -- local dir = string.gsub(vim.v.termrequest, '\x1b]7;file://[^/]*', '')
        -- vim.api.nvim_buf_set_var(ev.buf, 'osc7_dir', dir)
        -- if vim.o.autochdir and vim.api.nvim_get_current_buf() == ev.buf then
        --     vim.cmd.cd(dir)
        -- end
    end
})
