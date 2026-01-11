return {

    {
        'lewis6991/gitsigns.nvim',
        -- enabled = false,
        event = 'BufRead',
        config = function()
            -- TODO! review config options and other features (just added it for gutter signs for now)
            -- config: https://github.com/lewis6991/gitsigns.nvim#%EF%B8%8F-installation--usage
            require('gitsigns').setup()
        end,
    },

}
