--
-- *** critical notee to read when having issues:
-- FYI clipboard setting used when you don't specify the register to yank to, i.e. `yy` vs `"+yy`
vim.o.clipboard = 'unnamedplus'
-- unnamedplus => use +/* register by default now
-- - which on macOS are wired to system clipboard for yank/paste
-- - and below, I override the macOS clipboard provider too (as well as for SSH)
--   - forces OSC52 always (works locally too)
-- b/c, normally `yy` would yank to the " register
--   - " is an isolated clipboard within vim
--   - hence the need to use "+yy to yank to the system clipboard
-- so, setting unnamedplus => makes `yy` == `"+yy` and `p` == `"+p` etc.

-- FYI `:registers` will show if there is a clipboard provider for +/* registers
--   might have failure like this: (from ubuntu before I set clipboard provider below)
--     clipboard: No provider. Try ":checkhealth" or ":h clipboard".

-- *** set clipboard provider (for +/*) to use osc52
--  FYI nvim 10.2+ has smth builtin and it doesn't work over SSH
--    - `:h clipboard-osc52` which covers the defaults W.R.T. osc
--    - so I am manually specifying to use osc52 module and this works!
--  FYI also, the new nvim 10.2+ mechanism is disabled when setting clipboard=unnamedplus above
--    - thus, another reason to specify this manually
--
--  FYI always using OSC52 for now, unless presents issues...
--  - in fact I don't recall paste working w/ the builtin macos provider (default nvim provider)
--  - so this might actually be an improvement locally
--  PRN disable paste support over OSC52 to stop the annoying paste prompt
--  - clipboard reporting warning in iterm2,
--  - or just always enable it...  although then you get the lovely "contents of pasteboard reported"
--  - FYI even if I disable passte, Cmd+V still works for most use cases
--    - obviously not for `p` command (and any vimscript/lua funcs that depend on it)

-- FYI test cases to consider when changing anything
-- - local, on a mac, can you
--   - copy via `yy` to system clipboard (use Cmd+V to validate)
--   - paste from clipboard (copy from another program) using `p` normal mode command
-- - remote (over SSH)
--   - copy using osc (use command above to test too)
--   - `yy` to copy to remote clipboard
--   - `p` from remote clipboard
-- *** test osc52 shell support w/o nvim:
--    echo -e "\033]52;;$(echo -n jerk | base64)\a"
--    # should paste "jerk" if works (works local and remote)

function paste_from(register)
    -- THIS is gonna cause issues on windows/remotes (resolve later)
    --   also might cause issues if I SSH into a mac that has pbpaste (deal with that later)
    function pbpaste()
        -- pbpaste bbypasses ypasses showing "clipboard contents reported" on every single paste
        local handle = io.popen("pbpaste")
        local clipboard_content = handle:read("*a")
        handle:close()
        return clipboard_content
    end

    local success, result = pcall(pbpaste)
    if success then
        print("worked", result)
        return result
    end

    print("fallback", result)

    -- fallback to getreg
    return vim.fn.getreg(register)
end

vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
    -- -- DISABLE PASTE over OSC52 -- wire up provider to paste from cached version of register in VIM, not reading remote clipboard on paste
    -- paste = {
    --     -- OK this just uses "cached" copy in the register, means I cannot read remote clipboard and that is fine, I DONT CARE, not gonna click ok on a prompt every time so until I say F it and always allow paste just use this... I have always had vim operate this way for paste anyways... all I really want is to copy to remote clipboard, w/in vim I don't need paste beyond vim
    --     ['+'] = function() return vim.fn.getreg('+') end,
    --     ['*'] = function() return vim.fn.getreg('*') end,
    -- },

    -- -- OSC52 paste:
    -- -- Fooo iterm2 has a bubble on every paste now... and no way to disable it?! WTF... "Clipboard contents reported"... that is not gonna be cool in video recordings... gah w/e safety paranoia people, you win
    -- paste = {
    --     ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    --     ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    -- },

    -- -- -- OSC52 paste:
    -- -- -- Fooo iterm2 has a bubble on every paste now... and no way to disable it?! WTF... "Clipboard contents reported"... that is not gonna be cool in video recordings... gah w/e safety paranoia people, you win
    -- paste = {
    --     ['+'] = function() return paste_from("+") end,
    --     ['*'] = function() return paste_from("*") end,
    -- },

}

-- -- wrong module now, but this can help troubleshoot w/o using the clipboard provider mechanism (which in prev testing swallowed errors in require non-existant module)
-- vim.keymap.set('n', '<leader>c', function()
--     require('osc52').copy_operator()
-- end, { expr = true })


-- Note that if you set your clipboard provider like the example above, copying
-- text from outside Neovim and pasting with <kbd>p</kbd> won't work. But you can
-- still use the paste shortcut of your terminal emulator (usually
-- -- <kbd>ctrl+shift+v</kbd>).
