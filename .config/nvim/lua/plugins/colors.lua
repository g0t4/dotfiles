return {

    -- {
    --     'Mofiqul/vscode.nvim'
    -- }, -- use "vscode" ... I added this in neovim, though my other theme is fine too it seem

    {
        'tomasiser/vim-code-dark', -- use "codedark" from my vimrc
	priority = 1000, -- highest to set this first, including termguicolors early too ( random errors tie back to race conditioon on setting termguicolors)
        config = function()
            vim.cmd [[
                colorscheme codedark
                set termguicolors
                ]]
        end
    },

    {
        "norcalli/nvim-colorizer.lua", -- colorize hex codes, etc
        event = require("event-triggers").buffer_with_content_events,
        config = function()
            require("colorizer").setup()
        end,
    },


    -- maybe:
    --  tjdevries/colorbuddy.nvim -- make it easier to define new color schemes

}
