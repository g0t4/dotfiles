-- FYI clipboard setting used when you don't specify the register to yank to, i.e. `yy` vs `"+yy`
vim.o.clipboard = 'unnamedplus'
-- unnamedplus => use +/* register by default now
-- - which on macOS are wired to system clipboard for yank/paste
-- - and below, I override the macOS provider too (as well as for SSH) and just use OSC52 always (so it works over SSH too)
-- so, normally `yy` would yank to the " register, which is an isolated clipboard within vim, hence the need to use "+yy to yank to the system clipboard
-- so, setting unnamedplus => makes `yy` == `"+yy` and `p` == `"+p` etc.

-- FYI `:registers` will show if there is a clipboard provider for +/* registers
--   might have failure like this: (from ubuntu before I set clipboard provider below)
--     clipboard: No provider. Try ":checkhealth" or ":h clipboard".

-- *** test osc52 shell support w/o nvim:
--    echo -e "\033]52;;$(echo -n jerk | base64)\a"
--    # should paste "jerk" if works (works local and remote)

-- *** set clipboard provider (for +/*) to use osc52
--   FYI nvim 10.2+ has smth builtin and it doesn't work over SSH, so I am manually specifying to use osc52 module and this works!
--   FYI also the new nvim 10.2+ mechanism appears disabled when setting clipboard=unnamedplus above, so I also needed this for that reason
--
--   FYI always using OSC52 for now, unless presents issues... in fact I don't recall paste working w/ the builtin macos provider... so this might actually be an improvement locally
--   PRN disable paste support over OSC52 to stop the annoying paste prompt (clipboard reporting warning in iterm2, or just always enable it... not sure it's that huge of a deal.... I mean, reading my clipboard sure that is dangerous but if someone has RCE on my remote env... probably just as much of a problem, or more so)
--     PRN wire up paste to be isolated again... so I can abate the damn warnings, I never cared about paste over SSH b/c I already have Cmd+V for that
vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    -- wire up provider to paste from cached version of register in VIM, not reading remote clipboard on paste
    paste = {
        -- OK this just uses "cached" copy in the register, means I cannot read remote clipboard and that is fine, I DONT CARE, not gonna click ok on a prompt every time so until I say F it and always allow paste just use this... I have always had vim operate this way for paste anyways... all I really want is to copy to remote clipboard, w/in vim I don't need paste beyond vim
        ['+'] = function() return vim.fn.getreg('+') end,
        ['*'] = function() return vim.fn.getreg('*') end,
    },

    -- OSC52 paste:
    -- paste = {
    --     ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    --     ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
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
