return {

    {
        -- surround with - add/rm () {} [] `` '' "" etc - like vscode, I really like that in vscode, esp in markdown to use code blocks on existing content
        'kylechui/nvim-surround', -- dot repeat! (wrap multiple things), jump to nearest pair?
        event = { "BufRead", "InsertEnter" },
        config = function()
            require('nvim-surround').setup({})
        end
        -- I really like this extension as I get used to the motions, its great, ysiw" bam! or ys$"... perfection (one step to select range and highlight it, super cumbersome w/o both together in one action)
    },

    -- can match with whitespace differences
    {
        "wurli/visimatch.nvim",
        enabled = true,
        opts = {

            -- ? any issues with > 100 lines?
            -- 100 feels fine, why would it matter?
            -- I'd think duplicates would be eliminated very early on short of a copy of an entire section/file?
            lines_upper_limit = 1000,

            -- btw other possilby interesting options:
            -- chars_lower_limit = 6 -- this kinda makes sense as the # of matches would explode with fewer chars
            -- hl_group = "Search",
            -- strict_spacing = false -- I love skipping spacing differences!
            --   ?? I'd love to see it ignore line comment indicators (at least at start of lines) so I can compare code that is commented out to other code that is not w/o uncomment it
            -- buffers = "filetype", -- options: 'current', 'all' or 'filetype' (which files to show matches in)
            -- case_insensitive = { "markdown", "text", "help" },
        },
    },
    --
    -- highlight selections like vscode, w/o limits (200 chars in vscode + no new lines)
    {
        "aaron-p1/match-visual.nvim",
        event = { "BufRead", "InsertEnter" },
        enabled = false,
    }, -- will help me practice using visual mode too
    -- FYI g,Ctrl-g to show selection length (aside from just highlighting occurrenes of selection)

    {
        -- https://github.com/justinmk/vim-sneak
        "justinmk/vim-sneak", -- easy jump to unique chars or groups of chars (like vscode find all occurences)
        -- interesting, not terrible... I need to take some time to try to get used to using it before I pass judgement...
        --    first thought is... I prefer search / over this.. b/c search I can keep typing a 3rd char...
        --    it is kinda like multi-line version of eyeliner
        --      I like that it shows you what highlights are forward as you move forwardand drops off previous ones.. and vice versa for reverse
        --      s => forward, S => backward
        --    if I dont use this... then why not map s => / ... / is awkward is my only issue with it
        --    btw s => cl  and S => cc  # and so far I haven't found a need to use s in normal mode... I like c/r alone so far... ... I do see a use for s to replace + stay in insert mode... and for sure cl is awkward but... how often do I need that?
        enabled = false,
        config = function()
            require("sneak").setup({})
            -- alternative mode more like easymotion (and IIAC like eyeliner):
            -- vim.cmd(" let g:sneak#label = 1 ")
        end,
    },

    -- mark unique letters to jump to:
    --  use "unblevable/quick-scope" -- quick scope marks jump
    {
        "jinh0/eyeliner.nvim", -- lua impl, validated this actually works good and the color is blue OOB which is nicely subtle, super useful on long lines!
        enabled = true,
        event = { "BufRead", "InsertEnter" },
        config = function()
            -- highlight customization:
            --   https://github.com/jinh0/eyeliner.nvim?tab=readme-ov-file#-customize-highlight-colors
            -- FYI IIAC eyeliner is checking if these are defined and not redefining... so order matters to customize vs replace these
            --    I say this b/c if I define these here, the default colors aren't applied... whereas if I apply after eyeliner is loaded, these just alter its definitions
            --
            -- colorful:
            -- defaults (via :highlight Eyeliner*):
            vim.api.nvim_set_hl(0, 'EyelinerPrimary', { fg = '#569cd6', underline = true, bold = true }) -- default fg = '#569cd6'
            vim.api.nvim_set_hl(0, 'EyelinerSecondary', { fg = '#c586c0', underline = true }) -- default fg = '#c586c0'
            --      EyelinerDimmed xxx cleared   (default)
            -- vim.api.nvim_set_hl(0, 'EyelinerDimmed', { fg = '#00FF00' }) -- only applies if highlight_on_key = true FYI
            --
            -- if only show chars after fFtT then the color can be more obnixious, in fact it should be to help it pop out (flash on)
            -- if always visible then arguably should be more subtle (that said this can be hard to see then when I do need it)... maybe another argument for highlight after on always?
            --
            -- subtle => underline only:
            -- vim.api.nvim_set_hl(0, 'EyelinerPrimary', { bold = true, underline = true })
            -- vim.api.nvim_set_hl(0, 'EyelinerSecondary', { underline = true })

            require("eyeliner").setup {
                highlight_on_key = false, -- highlight on key press, instead of before?
                -- pros: high on key doesn't mess up syntax highlights until the time comes to actually use it
                --   only shows relevant chars for the direction of the jump (so if I jump left, only shows left chars), which is really nice
                --   I really like that it flashes on to help me immediately hone in on the char I want (or nearby), it's like flashing the chars after f... I really like that too
                --   quickly find out I hit the wrong key (f when I meant F)... yes, though that is a problem that should go away with practice... so not a primary factor
                -- cons: always showing helps me remember to use it, its been helping prime me to use it
                --   by the time I hit fFtT its too late to use 2f or 2F ... can repeat to fix for it but then this starts to turn into guessing jumps? guess is it 1 or 2 or 3... then fFtT
                --   BIG CON => don't see chars for repeating the jump! so you'd have to fFtT to have it show again! ouch
                -- compromise: underscore highlight only? so color is less an issue but always visible?
                --
                --
                dim = true, -- only applies to highlight_on_key = true, was hoping maybe it would apply when I hit fFtT always!
            }
        end
    },


    {
        -- *** smooth scrolling
        "karb94/neoscroll.nvim",
        event = { "BufRead", "InsertEnter" },
        config = function()
            local neoscroll = require('neoscroll')
            -- additional/custom keybindings, why aren't PageUp/Down OOB? any reason why I shouldn't remap those too?
            -- default mappings: https://github.com/karb94/neoscroll.nvim/blob/master/lua/neoscroll/init.lua#L411-L424
            local keymap = {
                -- scroll full page:
                ["<C-b>"]      = function() neoscroll.ctrl_b({ duration = 350 }) end, -- 450 default
                ["<C-f>"]      = function() neoscroll.ctrl_f({ duration = 350 }) end, -- 450 default
                ["<PageUp>"]   = function() neoscroll.ctrl_b({ duration = 350 }) end, -- not mapped by neoscroll
                ["<PageDown>"] = function() neoscroll.ctrl_f({ duration = 350 }) end, -- not mapped by neoscroll
                --
                -- scroll half page:
                -- ["<C-u>"]      = function() neoscroll.ctrl_u({ duration = 250 }) end, -- 250 default
                -- ["<C-d>"]      = function() neoscroll.ctrl_d({ duration = 250 }) end, -- 250 default

                -- scroll a "few" line(s):
                -- FYI benefit is # lines is relative to size of window (and if I resize the vim instance, it correctly adjusts on the fly with ratio below)
                -- TODO go back to using relative line count scroll instead of default 1 line?
                --    if so, I need to update <C-S-e> and <C-S-y> to use relative line count too
                ["<C-y>"]      = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 50 }) end, -- 100 default
                ["<C-e>"]      = function() neoscroll.scroll(0.1, { move_cursor = false, duration = 50 }) end, -- 100 default (feels slow)
                -- FYI love move_cursor param! allows me to use original C-e/y design and have a scrollunder variant:
                ["<C-S-y>"]    = function() neoscroll.scroll(-0.1, { move_cursor = true, duration = 50 }) end, -- 100 default
                ["<C-S-e>"]    = function() neoscroll.scroll(0.1, { move_cursor = true, duration = 50 }) end, -- 100 default (feels slow)
                -- FYI neoscroll is more than just about smooth scroll, it's a tool to design all sorts of scrolls

                --
                -- scroll cursor line to top/middle/bottom:
                -- 150 feels fine (even slow sometimes) for these, esp zz which often has a minimal move to make
                ["zt"]         = function() neoscroll.zt({ half_win_duration = 150 }) end, -- 250 half_win_duration default
                ["zz"]         = function() neoscroll.zz({ half_win_duration = 150 }) end, -- 250 half_win_duration default
                ["zb"]         = function() neoscroll.zb({ half_win_duration = 150 }) end, -- 250 half_win_duration default, too slow when move is large (top line to bottom = 2x250 = 500ms)
            }
            local modes = { 'n', 'v', 'x' }
            for key, func in pairs(keymap) do
                vim.keymap.set(modes, key, func)
            end
            neoscroll.setup({
                mappings = {
                    -- FYI make sure you uncomment here if you comment out customizations above
                    -- remove keys that you want to customize, else neoscroll will redefine them
                    '<C-u>', -- 250 default works good
                    '<C-d>', -- 250 default works good
                    -- '<C-b>',
                    -- '<C-f>',
                    -- '<C-y>',
                    -- '<C-e>',
                    -- 'zt',
                    -- 'zz',
                    -- 'zb',
                    -- 'G', -- I expect this to be jarring and would never wanna wait 250ms per page up/down!
                    -- 'gg',
                },
                -- easing = "quartic", -- I think I prefer linear default
            })
        end
    }, -- smooth scrolling? ok I like this a bit ... lets see if I keep it (ctrl+U/D,B/F has an animated scroll basically) - not affect hjkl/gg/G
    -- also works with zb/zt/zz which I wasn't aware of but looks useful => zz = center current line! zt/zb = curr line to top or bottom... LOVE IT!
    -- this scratches an itch I had about how it is hard to tell where I am jumping to with page up/down half page up /down etc... this makes it obvious where the movement is headed, long term I might become annoyed by this but its a useful idea... after all we have half page up/down me thinks for a reason that you can see the scroll easier than one full page jump


    {
        -- *** indent guides (vertically, like vscode plugin)
        -- FYI iterm2 select copies guides as pipe char... not worse thing as I dont wanna use select for copying anyways so MEH for now
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            local hooks = require "ibl.hooks"
            hooks.register(
                hooks.type.WHITESPACE,
                hooks.builtin.hide_first_space_indent_level -- I like excluding this one, less clutter, right?
            )
            -- :h config.indent▏
            require("ibl").setup {
                indent = {
                    -- highlight = highlight, -- TODO what was this supposed to be for? vestigial? I commented out b/c its broken anyways, FYI this is for setting a highlight group to use for the indent guides
                    char = "▏",
                }
            }
        end
    },

    -- use 'machakann/vim-sandwich' -- alternative?
    --
    -- PRN revisit autoclose, try https://github.com/windwp/nvim-autopairs (uses treesitter, IIUC)
    -- -- https://github.com/m4xshen/autoclose.nvim
    -- use 'm4xshen/autoclose.nvim' -- auto close brackets, quotes, etc
    -- require('autoclose').setup({
    --   -- ? how do I feel about this and copilot coexisting? seem to work ok, but will closing it out ever be an issue for suggestions
    --   -- ? review keymaps for conflicts with coc/copilot/etc
    --   filetypes = { 'lua', 'python', 'javascript', 'typescript', 'c', 'cpp', 'rust', 'go', 'html', 'css', 'json', 'yaml', 'markdown' },
    --   ignored_next_char = "[%w%.]", -- ignore if next char is a word or period
    --
    --   -- ' disable_command_mode = true, -- disable in command line mode AND search /, often I want to search for one " or [[ and dont want them closed
    --
    -- })
    --
    -- FYI I don't need autoclosing tags, copilot does this for me, and it suggests adding them after I add the content
    --   PLUS when I use auto close end tag, it conflicts with copilot suggestions until I break a line... so disable this for now
    --   PRN maybe I can configure this to do renames only? (not add on open tag), that said how often do I do that, I dunno?
    -- use 'windwp/nvim-ts-autotag' -- auto close html tags, auto rename closing too
    -- require('nvim-ts-autotag').setup()

    -- TODO paste with indent?




}
