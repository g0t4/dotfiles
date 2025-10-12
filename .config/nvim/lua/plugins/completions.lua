--
-- * insert mode completions:
local use_coc_completions = true
local use_cmp_completions = false
local use_nvim_0_11_completions = true
--
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
-- SUPER SLOPPY hack to just try nvim-cmp, not a robust config at all,  just wanted to test it w/ supermaven is all
-- nvim-cmp definitely feels super slow, but I should extensively test it before writing it off, esp for things coc fails at, i.e. refactoring in many cases
-- would need formatting to work too
-- would need to take coc-config.vim and replciate as much as it as is possible
-- FYI also has cmdline completions, would be alternative to wilder/wildmenu?
local plugin_lspconfig = {
    enabled = use_cmp_completions,
    "neovim/nvim-lspconfig",
    config = function()
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        lspconfig.lua_ls.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
                -- code formatting works
                -- client.server_capabilities.documentFormattingProvider = true
                -- FYI see coc-config.vim for my current keymaps
                -- FYI also would need to generalize this to all LSPs, not just lua
                -- FYI my code comment coloring highlight groups are overriden by sematnic token highlights?
                local buffer_keymap_options = { noremap = true, silent = true, buffer = bufnr }

                local foo = "bar"
                local bar = "foo"

                print(foo .. " " .. bar)
                local baz = "foo"


                -- too can I get these in popup windows? currently in cmdline
                vim.keymap.set('n', 'gd',
                    '<cmd>lua vim.lsp.buf.definition()<CR>', buffer_keymap_options)
                vim.keymap.set('n', 'gy',
                    '<cmd>lua vim.lsp.buf.type_definition()<CR>', buffer_keymap_options)
                -- TODO what to use for gi? since it is a builtin command
                vim.keymap.set('n', '<leader>gi',
                    '<cmd>lua vim.lsp.buf.implementation()<CR>', buffer_keymap_options)
                -- TODO what to use for gr? its a builtin cmd too, do I care about replacing it?
                vim.keymap.set('n', '<leader>gr',
                    '<cmd>lua vim.lsp.buf.references()<CR>', buffer_keymap_options)
                vim.keymap.set('n', '<F12>',
                    '<cmd>lua vim.lsp.buf.definition()<CR>', buffer_keymap_options)
                vim.keymap.set('n', '<F24>', -- Shift+F12 ==> F24
                    '<cmd>lua vim.lsp.buf.references()<CR>', buffer_keymap_options)
                -- FYI refs stay open, I kinda like that but want a fast way to close them, maybe a keymap?

                vim.keymap.set('n', '<Leader>cd',
                    '<cmd>lua vim.lsp.buf.document_symbol()<CR>', buffer_keymap_options)

                -- [g ]g for goto diagnostics
                vim.keymap.set('n', '[g',
                    '<cmd>lua vim.diagnostic.goto_prev()<CR>', buffer_keymap_options)
                vim.keymap.set('n', ']g',
                    '<cmd>lua vim.diagnostic.goto_prev()<CR>', buffer_keymap_options)

                -- K for hover docs
                vim.keymap.set('n', 'K',
                    '<cmd>lua vim.lsp.buf.hover()<CR>', buffer_keymap_options)
                -- TODO review my coc's ShowDocumentation() function and see if I can use it here too

                vim.keymap.set('n', '<Leader>rn',
                    '<cmd>lua vim.lsp.buf.rename()<CR>', buffer_keymap_options)
                vim.keymap.set('n', '<F2>',
                    '<cmd>lua vim.lsp.buf.rename()<CR>', buffer_keymap_options)


                -- TODO review my coc mappings for any inconsitencies?
                vim.keymap.set('n', '<Leader>f',
                    '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', buffer_keymap_options)
                vim.keymap.set('x', '<Leader>f',
                    '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', buffer_keymap_options)
                --#region
                vim.keymap.set('v', '<S-M-f>', '<cmd>lua vim.lsp.buf.range_formatting()<CR>',
                    buffer_keymap_options)
                vim.keymap.set('n', '<S-M-f>',
                    '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', buffer_keymap_options)
                -- in insert mode, allow formatting everything:
                vim.keymap.set('i', '<S-M-f>',
                    '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', buffer_keymap_options)

                vim.keymap.set('n', '<Leader>ca',
                    '<cmd>lua vim.lsp.buf.code_action()<CR>', buffer_keymap_options)

                -- TODO coc-config.vim's augroup mygroup?

                -- TODO left off here with coc-config.vim porting
            end,
            settings = {
                Lua = {
                    runtime = {
                        version = "LuaJIT", -- Neovim uses LuaJIT
                    },
                    diagnostics = {
                        globals = { "vim" }, -- Recognize the `vim` global
                    },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true), -- Make LSP aware of Neovim runtime files
                        checkThirdParty = false, -- Prevent prompts for third-party library analysis
                    },
                    telemetry = {
                        enable = false, -- Disable telemetry for privacy
                    },
                },
            },
        })

        -- Example LSP server setup (Python)
        lspconfig.pyright.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
                -- Optional: keymaps for LSP commands
                local buffer_keymap_options = { buffer = bufnr }
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, buffer_keymap_options)
                vim.keymap.set("n", "K", vim.lsp.buf.hover, buffer_keymap_options)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, buffer_keymap_options)
            end,
        })
    end,
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

        if not use_coc_completions then
            -- TODO on BufEnter? and maybe on file type?
            -- vim.api.nvim_create_autocmd('BufEnter', {
            --   callback = function()
            cmp.setup.buffer({
                sources = {
                    -- FYI https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources
                    -- { name = 'supermaven' }, -- didn't like this, feels limited to like 50 chars and why do that when I can use inline suggestions instead
                    { name = 'nvim_lsp' },
                    { name = "nvim_lua" },
                    -- TODO try snippets sourceds too
                    -- { name = 'vsnip' }, -- For vsnip users.
                    -- { name = 'luasnip' }, -- For luasnip users.
                    -- { name = 'ultisnips' }, -- For ultisnips users.
                    -- { name = 'snippy' }, -- For snippy users.
                },
                mapping = {
                    -- in buffer, makes sense to have diff mappings vs cmdline
                    -- TODO test w and w/o these mappings before adding them:
                    --     ["<Up>"] = cmp.mapping.select_prev_item(),
                    --     ["<Down>"] = cmp.mapping.select_next_item(),
                    --     ["<Tab>"] = cmp.mapping.select_next_item(),
                    --     ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                    --     ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    --     ["<C-Space>"] = cmp.mapping.complete(),
                    --     ["<C-e>"] = cmp.mapping.abort(),
                    -- FYI should scroll docs up/down in hover windows, test w/ vim. (shift+K to show it)
                    -- ['<PageUp>'] = cmp.mapping.scroll_docs(-4),
                    -- ['<PageDown>'] = cmp.mapping.scroll_docs(4),
                },
            })
            -- end
            -- })
        end

        if use_cmp_cmdline_search then
            require("plugins.completions.cmdline_cmp").setup()
        end
    end,
    dependencies = {
        -- PRN for only cmdline completions, I don't need all of these and could limt what I include
        'neovim/nvim-lspconfig',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'hrsh7th/nvim-cmp',
        'supermaven-inc/supermaven-nvim',

        -- optional deps to consider (i.e. snippets)
        -- 'L3MON4D3/LuaSnip',
        -- 'saadparwaiz1/cmp_luasnip',

    },
}

if use_nvim_0_11_completions then
    -- TODO! try standalone LSP in nvim 0.11! (completions, config, multi-client?, plus prev features, also LSP API looks good)
end

if use_nvim_0_11_cmdline_search then
    -- nvim had cmdline search (wildmenu, pum, etc...), is anything new for this in 0.11 (overlap with LSP completions?)
    require("plugins.completions.cmdline_nvim")
end

return {
    plugin_coc,
    plugin_lspconfig,
    plugin_nvim_cmp,
}
