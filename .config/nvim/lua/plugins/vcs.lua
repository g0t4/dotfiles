return {

    {
        -- benefits:
        -- - indicate changes: signs, word diff too!
        -- - stage/unstage hunk under cursor!
        -- - move next/prev hunk (changes)
        -- - blame, especially for current line (hover)
        -- - maybe the quickfix list of changes, navigable (I do want to use telescope for this given it's nice preview feature but right now it doesn't jump to the change within the file so it isn't as useful, it only jumps to the file with the change)
        -- - `ih` motion to select hunk (i.e. `vih`)
        -- * no gutter => visual cue that there are no outstanding changes for this file! (if using signs for changes)
        --
        -- cons: ?

        'lewis6991/gitsigns.nvim',
        -- enabled = false,
        event = 'BufRead',
        config = function()
            -- TODO! review config options and other features (just added it for gutter signs for now)
            --  try blame information in virtual text for current line only
            -- config: https://github.com/lewis6991/gitsigns.nvim#%EF%B8%8F-installation--usage
            require('gitsigns').setup {
                on_attach = function(bufnr)
                    local gitsigns = require('gitsigns')

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- * next change
                    map('n', ']c', function()
                        if vim.wo.diff then
                            -- don't alter ]c for diff views
                            vim.cmd.normal({ ']c', bang = true })
                        else
                            gitsigns.nav_hunk('next')
                        end
                    end)

                    -- * prev change
                    map('n', '[c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ '[c', bang = true })
                        else
                            gitsigns.nav_hunk('prev')
                        end
                    end)

                    -- TODO review and learn other :Gitsigns ___<TAB> subcommands
                    --
                    -- ? keymaps for
                    --    :Gitsigns show HEAD~3
                    --              show_commit ___
                    --            * blame

                    -- * hunk actions
                    map('n', '<leader>hs', gitsigns.stage_hunk) -- * toggles staged/unstaged
                    map('n', '<leader>hr', gitsigns.reset_hunk)
                    -- FYI careful w/ reset... removes unstaged changes! (still have to save though)

                    -- * selection actions
                    map('v', '<leader>hs', function()
                        gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
                    end)
                    map('v', '<leader>hr', function()
                        gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
                    end)

                    -- * buffer actions
                    map('n', '<leader>hS', gitsigns.stage_buffer)
                    map('n', '<leader>hR', gitsigns.reset_buffer)

                    map('n', '<leader>hp', gitsigns.preview_hunk)
                    -- useful to confirm a hunk before staging it... so make it just hi to make it faster to invoke
                    --   nevermind hp above is used for hover preview... I don't want hpi here
                    --   I will likely invoke this often!
                    map('n', '<leader>hi', gitsigns.preview_hunk_inline)

                    -- TODO how do I unstage hunk/selection/buffer?

                    -- * blame for current line!
                    map('n', '<leader>hb', function()
                        gitsigns.blame_line({ full = true })
                    end)

                    -- * diffthis
                    map('n', '<leader>hd', gitsigns.diffthis)
                    map('n', '<leader>hD', function()
                        gitsigns.diffthis('~')
                    end)

                    -- * quickfix list
                    map('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
                    map('n', '<leader>hq', gitsigns.setqflist)

                    -- * toggle features
                    map('n', '<leader>htb', gitsigns.toggle_current_line_blame)
                    map('n', '<leader>htw', gitsigns.toggle_word_diff) -- * LOVE word diff for modified lines!

                    -- **** hunk based text object! ****
                    map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = "text object hunk selection: i.e. vih, dih" })
                end
            }
        end,
    },

}
