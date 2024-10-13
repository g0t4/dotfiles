return {

    {
        -- surround with - add/rm () {} [] `` '' "" etc - like vscode, I really like that in vscode, esp in markdown to use code blocks on existing content
        'kylechui/nvim-surround', -- dot repeat! (wrap multiple things), jump to nearest pair?
        config = function()
            require('nvim-surround').setup({})
        end
        -- I really like this extension as I get used to the motions, its great, ysiw" bam! or ys$"... perfection (one step to select range and highlight it, super cumbersome w/o both together in one action)
    },

    -- highlight just word under cursor:
    { "RRethy/vim-illuminate" }, -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column
    --    sadly, not the current selection (https://github.com/RRethy/vim-illuminate/issues/196), I should write this plugin
    --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
    --    customizing:
    --      hi def IlluminatedWordText gui=underline
    --      hi def IlluminatedWordRead gui=underline
    --      hi def IlluminatedWordWrite gui=underline


    -- highlight selections like vscode, w/o limits (200 chars in vscode + no new lines)
    { "aaron-p1/match-visual.nvim" }, -- will help me practice using visual mode too
    -- FYI g,Ctrl-g to show selection length (aside from just highlighting occurrenes of selection)


    -- mark unique letters to jump to:
    --  use "unblevable/quick-scope" -- quick scope marks jump
    "jinh0/eyeliner.nvim", -- lua impl, validated this actually works good and the color is blue OOB which is nicely subtle, super useful on long lines!
    --
    {
        "karb94/neoscroll.nvim",
        config = function()
            require('neoscroll').setup()
        end
    }, -- smooth scrolling? ok I like this a bit ... lets see if I keep it (ctrl+U/D,B/F has an animated scroll basically) - not affect hjkl/gg/G
    -- also works with zb/zt/zz which I wasn't aware of but looks useful => zz = center current line! zt/zb = curr line to top or bottom... LOVE IT!
    -- this scratches an itch I had about how it is hard to tell where I am jumping to with page up/down half page up /down etc... this makes it obvious where the movement is headed, long term I might become annoyed by this but its a useful idea... after all we have half page up/down me thinks for a reason that you can see the scroll easier than one full page jump



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
