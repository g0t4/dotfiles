return {

    {
        'Mofiqul/vscode.nvim'
    }, -- use "vscode" ... I added this in neovim, though my other theme is fine too it seem

    {
        'tomasiser/vim-code-dark', -- use "codedark" from my vimrc
        config = function()
            vim.cmd [[
                colorscheme codedark
                set termguicolors
                ]]
        end
    },

    {
        "norcalli/nvim-colorizer.lua", -- colorize hex codes, etc
        config = function()
            require("colorizer").setup()
        end,
    },


    -- maybe:
    --  tjdevries/colorbuddy.nvim -- make it easier to define new color schemes

}