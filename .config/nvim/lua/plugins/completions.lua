-- boolean is simple way to toggle coc vs nvim-cmp
local use_coc = true
if (use_coc) then
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
        },

    }
else
    -- SUPER SLOPPY hack to just try nvim-cmp, not a robust config at all,  just wanted to test it w/ supermaven is all
    -- nvim-cmp definitely feels super slow, but I should extensively test it before writing it off, esp for things coc fails at, i.e. refactoring in many cases
    -- would need formatting to work too
    -- would need to take coc-config.vim and replciate as much as it as is possible
    -- FYI also has cmdline completions, would be alternative to wilder/wildmenu?
    return {
        {
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
                        local opts = { noremap = true, silent = true }

                        local foo = "bar"
                        local bar = "foo"

                        print(foo .. " " .. bar)
                        local baz = "foo"

                        -- too can I get these in popup windows? currently in cmdline
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd',
                            '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gy',
                            '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi',
                            '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr',
                            '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<F12>',
                            '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<S-F12>',
                            '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                        -- FYI refs stay open, I kinda like that but want a fast way to close them, maybe a keymap?

                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>cd',
                            '<cmd>lua vim.lsp.buf.document_symbol()<CR>', { noremap = true, silent = true })

                        -- [g ]g for goto diagnostics
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '[g',
                            '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', ']g',
                            '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)

                        -- K for hover docs
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K',
                            '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
                        -- TODO review my coc's ShowDocumentation() function and see if I can use it here too

                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>rn',
                            '<cmd>lua vim.lsp.buf.rename()<CR>', opts)


                        -- TODO review my coc mappings for any inconsitencies?
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>f',
                            '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'x', '<Leader>f',
                            '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)
                        --#region
                        vim.api.nvim_buf_set_keymap(bufnr, 'v', '<S-M-f>', '<cmd>lua vim.lsp.buf.range_formatting()<CR>',
                            opts)
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<S-M-f>',
                            '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)
                        -- in insert mode, allow formatting everything:
                        vim.api.nvim_buf_set_keymap(bufnr, 'i', '<S-M-f>',
                            '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)

                        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>ca',
                            '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

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
                                checkThirdParty = false,                           -- Prevent prompts for third-party library analysis
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
                        local opts = { buffer = bufnr }
                        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    end,
                })
            end,
        },

        {
            enabled = true,
            -- cmp instead:
            "hrsh7th/nvim-cmp",
            event = { "InsertEnter", "CmdlineEnter" }, -- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
            config = function()
                local cmp = require('cmp')

                -- TODO style supermaven completions:
                -- local lspkind = require("lspkind")
                -- lspkind.init({
                --   symbol_map = {
                --     Supermaven = "",
                --   },
                -- })
                -- vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", {fg ="#6CC644"})


                cmp.setup {
                    performance = {
                        debounce = 50, -- Adjust debounce timing to find the sweet spot
                    },
                    sources = cmp.config.sources(
                        {
                            -- { name = 'supermaven' },
                            { name = 'nvim_lsp' },
                            { name = "nvim_lua" },
                            -- TODO try snippets sourceds too
                            -- { name = 'vsnip' }, -- For vsnip users.
                            -- { name = 'luasnip' }, -- For luasnip users.
                            -- { name = 'ultisnips' }, -- For ultisnips users.
                            -- { name = 'snippy' }, -- For snippy users.
                        },
                        {
                            { name = 'buffer' },
                        }
                    ),
                    mapping = {
                        -- Use Up/Down arrow keys to navigate the menu
                        ["<Up>"] = cmp.mapping.select_prev_item(),
                        ["<Down>"] = cmp.mapping.select_next_item(),
                        -- Other useful mappings
                        ["<Tab>"] = cmp.mapping.select_next_item(),
                        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                        ["<CR>"] = cmp.mapping.confirm({ select = true }),
                        ["<C-Space>"] = cmp.mapping.complete(),
                        ["<C-e>"] = cmp.mapping.abort(),
                    },
                }

                -- FYI search completion works good (could standalone use it over wilder)
                -- Enable command-line completion for `/` and `?`
                cmp.setup.cmdline({ '/', '?' }, {
                    mapping = cmp.mapping.preset.cmdline(),
                    sources = {
                        { name = 'buffer' }
                    }
                })

                -- FYI command line completion works good (could standalone use it over wilder)
                -- Enable command-line completion for `:`
                -- TODO try snippets with CLI! sounds like fish abbrs!
                --    TODO https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#ultisnips--cmp-cmdline
                cmp.setup.cmdline(':', {
                    mapping = cmp.mapping.preset.cmdline(),
                    sources = cmp.config.sources({
                        { name = 'path' }
                    }, {
                        { name = 'cmdline' }
                    })
                })
            end,
            dependencies = {
                'neovim/nvim-lspconfig',
                'hrsh7th/cmp-nvim-lsp',
                'hrsh7th/cmp-nvim-lua',
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-path',
                'hrsh7th/cmp-cmdline',
                'hrsh7th/nvim-cmp',
                'supermaven-inc/supermaven-nvim',
            },
        },
    }
end