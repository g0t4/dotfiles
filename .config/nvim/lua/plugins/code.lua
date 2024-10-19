local buffer_with_content_events = require("event-triggers").buffer_with_content_events

return {

    {
        -- surround with - add/rm () {} [] `` '' "" etc - like vscode, I really like that in vscode, esp in markdown to use code blocks on existing content
        'kylechui/nvim-surround', -- dot repeat! (wrap multiple things), jump to nearest pair?
        event = buffer_with_content_events,
        config = function()
            require('nvim-surround').setup({})
        end
        -- I really like this extension as I get used to the motions, its great, ysiw" bam! or ys$"... perfection (one step to select range and highlight it, super cumbersome w/o both together in one action)
    },

    -- highlight selections like vscode, w/o limits (200 chars in vscode + no new lines)
    {
        "aaron-p1/match-visual.nvim",
        event = buffer_with_content_events,
    }, -- will help me practice using visual mode too
    -- FYI g,Ctrl-g to show selection length (aside from just highlighting occurrenes of selection)


    -- mark unique letters to jump to:
    --  use "unblevable/quick-scope" -- quick scope marks jump
    {
        "jinh0/eyeliner.nvim", -- lua impl, validated this actually works good and the color is blue OOB which is nicely subtle, super useful on long lines!
        event = buffer_with_content_events,
    },

    --
    {
        "karb94/neoscroll.nvim",
        event = buffer_with_content_events,
        config = function()
            require('neoscroll').setup()
        end
    }, -- smooth scrolling? ok I like this a bit ... lets see if I keep it (ctrl+U/D,B/F has an animated scroll basically) - not affect hjkl/gg/G
    -- also works with zb/zt/zz which I wasn't aware of but looks useful => zz = center current line! zt/zb = curr line to top or bottom... LOVE IT!
    -- this scratches an itch I had about how it is hard to tell where I am jumping to with page up/down half page up /down etc... this makes it obvious where the movement is headed, long term I might become annoyed by this but its a useful idea... after all we have half page up/down me thinks for a reason that you can see the scroll easier than one full page jump


    {
        -- *** indent guides (vertically, like vscode plugin)
        -- FYI iterm2 select copies guides as pipe char... not worse thing as I dont wanna use select for copying anyways so MEH for now
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            local highlight = {
                "RainbowRed",
                "RainbowYellow",
                "RainbowBlue",
                "RainbowOrange",
                "RainbowGreen",
                "RainbowViolet",
                "RainbowCyan",
            }

            local color_helpers = require "localz.color-helpers"
            local desaturate = color_helpers.desaturate_color_hex
            local brightness = color_helpers.adjust_brightness_hex
            local hooks = require "ibl.hooks"
            -- create the highlight groups in the highlight setup hook, so they are reset
            -- every time the colorscheme changes
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                local desat = 0.50
                local bright = 0.65
                vim.api.nvim_set_hl(0, "RainbowRed", { fg = brightness(desaturate("#9A4F56", desat), bright) })
                vim.api.nvim_set_hl(0, "RainbowYellow", { fg = brightness(desaturate("#B89A61", desat), bright) })
                vim.api.nvim_set_hl(0, "RainbowBlue", { fg = brightness(desaturate("#4A7FA6", desat), bright) })
                vim.api.nvim_set_hl(0, "RainbowOrange", { fg = brightness(desaturate("#A77A4C", desat), bright) })
                vim.api.nvim_set_hl(0, "RainbowGreen", { fg = brightness(desaturate("#7A9B62", desat), bright) })
                vim.api.nvim_set_hl(0, "RainbowViolet", { fg = brightness(desaturate("#9B64A7", desat), bright) })
                vim.api.nvim_set_hl(0, "RainbowCyan", { fg = brightness(desaturate("#3D818A", desat), bright) })
            end)

            require("ibl").setup { indent = { highlight = highlight } }
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
