--
-- * insert mode completions:
local use_coc_completions = false -- TODO ASAP GET OFF OF THIS... it is killing shutdown performance, murdering it at random
-- BTW git checkout d1689a48 (3 months back, before their stupid MCP server crap which probably caused this... works fine, no hanging on quit)

local use_cmp_completions = false
local use_nvim_native_lsp_completions = true

-- * cmdline completions:
local use_cmp_cmdline_search = true -- make sure to enable wilder via its enabled property
local use_nvim_0_11_cmdline_search = false -- IIAC this was added in 0.11 too?

local plugin_coc = {
    -- alternative but only has completions? https://neovimcraft.com/plugin/hrsh7th/nvim-cmp/ (example config: https://github.com/m4xshen/dotfiles/blob/main/nvim/nvim/lua/plugins/completion.lua)
    enabled = use_coc_completions,
    'neoclide/coc.nvim',
    branch = 'release',
    -- LSP (language server protocol) support, completions, formatting, diagnostics, etc
    -- 0.0.82 is compat with https://microsoft.github.io/language-server-protocol/specifications/specification-3-16/
    -- https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim (install extensions)
    -- sample config: https://raw.githubusercontent.com/neoclide/coc.nvim/master/doc/coc-example-config.vim

    -- FYI its ok to load this always, that said it might be nice to only load this on specific filetypes that I configure it to work with
    event = { "BufRead", "InsertEnter" },

    config = function()
        vim.cmd('source ~/.config/nvim/lua/plugins/completions/coc/keymaps.vim')
        require("plugins.completions.coc.keymaps")
    end,
    -- CocConfig (opens coc-settings.json in buffer to edit) => from ~/.config/nvim/coc-settings.json
    --   https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim#add-some-configuration
    --   it works now (Shift+K on vim.api.nvim_win_get_cursor(0) shows the docs for that function! and if you remove the coc-settings.json and CocRestart then it doesn't show docs... yay
    --   why? to provide the LSP with vim globals (i.e. to show docs Shift+K) and for coc's completion lists
    --
    -- FYI all language server docs: https://github.com/neoclide/coc.nvim/wiki/Language-servers#lua
    --    each LSP added can be configured in coc-settings.json
}
local plugin_nvim_cmp = {
    enabled = use_cmp_completions or use_cmp_cmdline_search,
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" }, -- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
    config = function()
        local cmp = require('cmp')

        -- PRN style supermaven completions:
        -- local lspkind = require("lspkind")
        -- lspkind.init({
        --   symbol_map = {
        --     Supermaven = "",
        --   },
        -- })
        -- vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", {fg ="#6CC644"})

        -- cmp.setup {
        --     -- Global Setup (for all scenarios) => use buffer/cmdline specific instead
        --     performance = {
        --         debounce = 50, -- Adjust debounce timing to find the sweet spot
        --     },
        -- }

        if use_cmp_completions then
            cmp.setup.buffer({
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'nvim_lua' },
                },
            })
        else
            -- Keep cmp entirely out of source buffers while using native LSP completion.
            cmp.setup({ enabled = function() return vim.fn.getcmdtype() ~= '' end })
        end

        if use_cmp_cmdline_search then
            require("plugins.completions.cmdline_cmp").setup()
        end
    end,
    dependencies = vim.list_extend({
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
    }, use_cmp_completions and { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-nvim-lua' } or {}),
}

if use_nvim_native_lsp_completions then
    require("plugins.completions.nvim_native_lsp")
end

if use_nvim_0_11_cmdline_search then
    -- nvim had cmdline search (wildmenu, pum, etc...), is anything new for this in 0.11 (overlap with LSP completions?)
    require("plugins.completions.cmdline_nvim")
end

return {
    plugin_coc,
    plugin_nvim_cmp,
}
