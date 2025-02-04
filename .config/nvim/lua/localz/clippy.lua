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
    -- RATIONALE:
    -- - I hate that iTerm shows clipboard contents reported warning when using OSC52 paste alone
    -- - so, why not use pbpaste (if present) to paste from the clipboard
    --   - obviously this only works with local iTerm shells
    -- - then for fallback, either try osc52 paste OR just use cached register
    --   - this would be for remote SSH connections
    -- - one caveat, if I SSH into a mac
    --   - pbpaste will use the remote user's clipboard
    --   - doesn't work then to paste
    --   - TODO if env var SSH_CONNECTION is set, use OSC52?

    function pbpaste()
        -- pbpaste bbypasses ypasses showing "clipboard contents reported" on every single paste
        local handle = io.popen("pbpaste")
        local clipboard_content = handle:read("*a")
        handle:close()
        return clipboard_content
    end

    -- contents is a string
    local success, contents = pcall(pbpaste)
    if success then
        -- split on \n (newline), otherwise, messes up multi line pastes
        local lines_list = vim.split(assert(contents), '\n')

        -- second item in response list (table) is register type spec (see :h getreg)
        --   if its empty I get:
        --     "clipboard: provider returned invalid data"
        --        BTW it can be deceptive when this fails, b/c it falls back to whatever was last copied (cached) in nvim)...
        --           so make sure to test it by copying something exteranl to nvim
        --           also the warning message is one liner and easy to miss
        --   otherwise with '' seems fine and works to copy from macos clipboard!
        return { lines_list, '' }
    end

    -- SHOULD ONLY ARISE if LOCAL ISSUES, ONCE I MAP SSH connects to OSC52
    vim.notify("Failed to run pbpaste to get clipboard contents, using cached register instead.", vim.log.levels.ERROR)
    return vim.fn.getreg(register)
end

vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },

    -- *** paste option 1 - ALWAYS use osc paste:
    -- -- FYI iterm will always at least say "contents of pasteboard reported"...
    -- --   - no way to disable that message
    -- --   - that actually isn't that big of a deal, possibly..
    -- --     - we shall see if it fux up my course recordings
    -- --     - if so, I can frame hold over any super annoying parts
    -- --   - and if you dont mark "always" approve then it will prompt every time
    -- --     - gotta love people that don't understand prompt fatigue
    -- paste = {
    --     ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    --     ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    -- },

    -- *** paste option 2 - use vim registers for paste
    -- -- *** FYI... paste provider funcs must RETURN a LIST [ contents, register_type_spec ]
    --    otherwise it will fail with:
    --       "clipboard: provider returned invalid data"
    --       then, it ignores whatever you returned and does a fallback
    --         IIAC to cache registers to)
    --    - IOTW, won't be able to paste from external (remote, macos) clipboar
    --    register_type_spec:
    --      see `:h setreg()`
    --      "c"/"v" == charwise mode
    --      "l"/"V" == linewise mode
    --      "b"/"<CTRL-V>" == blockwise-visual mode
    --
    -- !!! WRONG RETURN SIGNATURE?
    -- paste = {
    --     ['+'] = function() return vim.fn.getreg('+') end,
    --     ['*'] = function() return vim.fn.getreg('*') end,
    -- },

    -- -- OSC52 paste:
    -- -- Fooo iterm2 has a bubble on every paste now... and no way to disable it?! WTF... "Clipboard contents reported"... that is not gonna be cool in video recordings... gah w/e safety paranoia people, you win
    -- DRAWBACK:
    -- FYI also reports:
    --    clipboard: provider returned invalid data
    -- !!! HRM... maybe my function return info is wrong, does it require more than just a string!
    paste = {
        ['+'] = function() return paste_from("+") end,
        ['*'] = function() return paste_from("*") end,
    },
}

if os.getenv("SSH_CONNECTION") then
    -- ??? OR fallback to register cached copy instead (most pasting works)?
    --   and then CMD+V is only way to paste from remote clipboard

    vim.g.clipboard = {
        name = 'OSC 52 both',
        copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        }
    }
end

-- -- wrong module now, but this can help troubleshoot w/o using the clipboard provider mechanism (which in prev testing swallowed errors in require non-existant module)
-- vim.keymap.set('n', '<leader>c', function()
--     require('osc52').copy_operator()
-- end, { expr = true })
