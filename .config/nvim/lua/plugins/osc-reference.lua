
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

        if string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;A' then
            print("  prompt_start A")
        elseif string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;B' then
            print('  ??? B')
        elseif string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;C' then
            print('  command_start C')
            -- COMMAND started
        elseif string.sub(vim.v.termrequest, 1, 7) == '\x1b]133;D' then
            print('  command_end D')
            -- COMMAND finished
        end

        -- fodder from vim docs examples to cd on dir change in terminal
        -- local dir = string.gsub(vim.v.termrequest, '\x1b]7;file://[^/]*', '')
        -- vim.api.nvim_buf_set_var(ev.buf, 'osc7_dir', dir)
        -- if vim.o.autochdir and vim.api.nvim_get_current_buf() == ev.buf then
        --     vim.cmd.cd(dir)
        -- end
    end
})
