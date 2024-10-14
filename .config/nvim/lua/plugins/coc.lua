return {

    {
        -- alternative but only has completions? https://neovimcraft.com/plugin/hrsh7th/nvim-cmp/ (example config: https://github.com/m4xshen/dotfiles/blob/main/nvim/nvim/lua/plugins/completion.lua)
        'neoclide/coc.nvim',
        branch = 'release',
        -- LSP (language server protocol) support, completions, formatting, diagnostics, etc
        -- 0.0.82 is compat with https://microsoft.github.io/language-server-protocol/specifications/specification-3-16/
        -- https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim (install extensions)
        -- sample config: https://raw.githubusercontent.com/neoclide/coc.nvim/master/doc/coc-example-config.vim

        -- FYI its ok to load this always, that said it might be nice to only load this on specific filetypes that I configure it to work with
        event = require('event-triggers').buffer_with_content_events,

        config = function()
            vim.cmd('source ~/.config/nvim/lua/plugins/vimz/coc-config.vim')
        end,
        -- CocConfig (opens coc-settings.json in buffer to edit) => from ~/.config/nvim/coc-settings.json
        --   https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim#add-some-configuration
        --   it works now (Shift+K on vim.api.nvim_win_get_cursor(0) shows the docs for that function! and if you remove the coc-settings.json and CocRestart then it doesn't show docs... yay
        --   why? to provide the LSP with vim globals (i.e. to show docs Shift+K) and for coc's completion lists
        --
        -- FYI all language server docs: https://github.com/neoclide/coc.nvim/wiki/Language-servers#lua
        --    each LSP added can be configured in coc-settings.json

    }
}
