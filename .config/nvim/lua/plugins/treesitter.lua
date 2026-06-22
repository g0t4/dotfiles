require("non-plugins.treesitter.harmony")
require("non-plugins.treesitter.qwen_chatml")

return {

    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        -- enabled = false,
        -- TODO define my own text objects to use with motions like yi_ or ya_ or vi/va_ ...
        --  directly links captures with custom text objects!
        -- * try with your harmony grammar (i.e. select current message)
        config = function()
            do return end

            require 'nvim-treesitter.configs'.setup {
                textobjects = {
                    select = {
                        enable = true,

                        -- Automatically jump forward to textobj, similar to targets.vim
                        lookahead = true,

                        keymaps = {
                            -- You can use the capture groups defined in textobjects.scm
                            ["af"] = "@fucker.around",
                            ["if"] = "@fucker.inner",
                        },
                        -- You can choose the select mode (default is charwise 'v')
                        --
                        -- Can also be a function which gets passed a table with the keys
                        -- * query_string: eg '@function.inner'
                        -- * method: eg 'v' or 'o'
                        -- and should return the mode ('v', 'V', or '<c-v>') or a table
                        -- mapping query_strings to modes.
                        -- selection_modes = {
                        --     ['@parameter.outer'] = 'v', -- charwise
                        --     ['@function.outer'] = 'V', -- linewise
                        --     ['@class.outer'] = '<c-v>', -- blockwise
                        -- },
                        -- If you set this to `true` (default is `false`) then any textobject is
                        -- extended to include preceding or succeeding whitespace. Succeeding
                        -- whitespace has priority in order to act similarly to eg the built-in
                        -- `ap`.
                        --
                        -- Can also be a function which gets passed a table with the keys
                        -- * query_string: eg '@function.inner'
                        -- * selection_mode: eg 'v'
                        -- and should return true or false
                        include_surrounding_whitespace = false,
                    },
                },
            }
        end,
    },

    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main', -- IIUC for nvim 0.12+
        -- branch = 'master' -- for nvim 0.11 (and earlier)
        lazy   = false,
        build  = ":TSUpdate",

        event  = { "BufRead", "InsertEnter" },

        config = function()
            -- nvim ships with these parsers now: C - Lua - Markdown - Vimscript - Vimdoc - Treesitter query files |ft-query-plugin|
            require('nvim-treesitter').install { "python", "javascript", "typescript", "html", "css", "json", "yaml", }
            -- v0.12+ notes:
            -- - nvim owns treesitter highlighting, folding
            -- - nvim-treesitter is a parser register/compiler
            --   + extra features: indent, textobjects
            --   - :InspectTree
            --   - :TSModuleInfo is gone now OR am I not setting up nvim-treesitter correctly now?

            -- modify RTP to find queries (and theoretically my parsers too)
            -- FYI! if you move this RTP modification, make sure it runs AFTER lazy is started
            --   lazy will wipe RTP changes that happen before it loads
            --   i.e. if you move these two lines to top of this module (not in config here for nvim-treesitter)... they will be wiped out by the time nvim fully loads
            --
            --   FYI I left this here in config for nvim-treesitter just so it is all together with my other treesitter config
            --   - otherwise I could move this to a non-plugin module and load it after lazy starts
            --
            vim.opt.runtimepath:append(vim.fn.expand("~/repos/github/g0t4/tree-sitter-harmony"))
            vim.opt.runtimepath:append(vim.fn.expand("~/repos/github/g0t4/tree-sitter-qwen-chatml"))
            --  verify queries found:
            --  :echo globpath(&rtp, 'queries/qwen_chatml/*', 1, 1)
            --  :echo globpath(&rtp, 'queries/harmony/*', 1, 1)

            -- * manually add parser instead of nvim-treesitter
            --   ([re]move parsers out of ~/.local/share/nvim/lazy/nvim-treesitter/parser/ dir)
            --   restart neovim and try start treesitter highlighting => make sure fails before try loading own:
            --      vim.treesitter.start()
            --   then register manually:
            vim.treesitter.language.add("qwen_chatml",
                {
                    path = vim.fn.expand("~/repos/github/g0t4/tree-sitter-qwen-chatml/qwen-chatml.dylib"),
                })
            vim.treesitter.language.add("harmony",
                {
                    path = vim.fn.expand("~/repos/github/g0t4/tree-sitter-harmony/harmony.dylib"),
                })
            -- ? wasm builds?
            --   TODO also I'm fine w/ letting nvim-treesitter handle compiling my parsers
            --
            -- TODO read `:h treesitter-language-injections` apparently nothing to config for this
            --
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    -- * auto load treesitter based on what each filetype supports
                    local bufnr = args.buf
                    local filetype = vim.bo[bufnr].filetype

                    local ok = pcall(vim.treesitter.start, bufnr)
                    if not ok then
                        return
                    end

                    local folds_queries_exist = vim.treesitter.query.get(filetype, "folds")
                    if folds_queries_exist then
                        -- https://neovim.io/doc/user/fold.html (FYI can use other methods like indent, syntax, manual, etc... for now I will try ts based)
                        vim.wo.foldmethod = 'expr'
                        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                        vim.o.foldenable = false -- no autofolding, just manual after open file
                    end

                    local indent_queries_exist = vim.treesitter.query.get(filetype, "indents")
                    if indent_queries_exist then
                        -- * nvim-treesitter indentation (experimental)
                        -- FYI IIUC this is gonna be mainlined in nvim 1.0?
                        --  at which time I should switch to its API to start/enable
                        vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })

            -- TODO is incremental_selection still a thing in nvim-treesitter main branch?
            -- incremental_selection = {
            --     -- similar to Ctrl+W in jetbrains IDEs
            --     enable = true,
            --     keymaps = {
            --         init_selection = 'gnn', -- Start selection
            --         node_incremental = 'grn', -- Expand to the next node
            --         scope_incremental = 'grc', -- Expand to the next scope
            --         node_decremental = 'grm', -- Shrink selection
            --     },
            -- },

            --   https://github.com/nvim-treesitter/nvim-treesitter#adding-custom-languages
            -- * custom grammars (i.e. ones I am hacking on, or not in official sets)
            -- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
            --
            -- TODO! setup nvim-treesitter for my parsers
            -- parser_config.harmony = {
            --     install_info = {
            --         url = "~/repos/github/g0t4/tree-sitter-harmony",
            --         files = { "src/parser.c" },
            --         -- queries => use RTP (no magic this way)
            --     }
            -- }
            --
            -- parser_config.qwen_chatml = {
            --     install_info = {
            --         url = "~/repos/github/g0t4/tree-sitter-qwen-chatml",
            --         files = { "src/parser.c" },
            --         -- generate = true,
            --         -- generate_from_json = false,
            --         -- queries => use RTP (no magic this way)
            --         -- make sure name shows in :TSModuleInfo
            --         --   :TSInstall qwen_chatml
            --         -- :TSUpdate -- IIUC recompile it when you change it... not sure if it is automatic?
            --     }
            -- }
            --

            -- * v0.12 + nvim-treesitter main config working!
            vim.api.nvim_create_autocmd('User', {
                pattern = 'TSUpdate',
                callback = function()
                    require('nvim-treesitter.parsers').test = {
                        install_info = {
                            -- TODO! figure out how to build with nvim-treesitter main...
                            --  TODO! right now I have test.so in parser dir in nvim-treesitter so I am fine (loads fine)... so I don't need this until I need to rebuild?
                            --  :TSInstall test
                            --   fails... see :TSLog for details
                            --
                            -- info(install/test): Downloading tree-sitter-test...
                            -- trace: running job: (cwd=/Users/wesdemos/repos/github/g0t4/tree-sitter-harmony) curl --silent --fail --show-error --retry 7 -L https://github.com/tree-sitter-grammars/tree-sitter-test/archive/main.tar.gz --output /Users/wesdemos/.cache/nvim/tree-sitter-test.tar.gz
                            -- trace: stderr -> curl: (56) The requested URL returned error: 404
                            -- error(install/test): Error during download: curl: (56) The requested URL returned error: 404
                            --
                            url = "https://github.com/tree-sitter-grammars/tree-sitter-test",
                            files = { "src/parser.c", "src/scanner.c" }, -- TODO is this still needed?
                            branch = 'master', -- will use 'main' now as default and shit a brick on :TSInstall test...
                            --
                            -- TODO do I need any of these?
                            -- optional entries (from nvim-treesitter docs: https://github.com/nvim-treesitter/nvim-treesitter#adding-custom-languages)
                            -- location = 'parser', -- only needed if the parser is in subdirectory of a "monorepo"
                            -- generate = true, -- only needed if repo does not contain pre-generated `src/parser.c`
                            -- generate_from_json = false, -- only needed if repo does not contain `src/grammar.json` either
                            -- queries = 'queries/neovim', -- also install queries from given directory
                        },
                    }
                    require('nvim-treesitter.parsers').cst = {
                        install_info = {
                            url = "https://github.com/tree-sitter-grammars/tree-sitter-cst",
                            files = { "src/parser.c" }, -- TODO is this still needed?
                            branch = 'master',
                            -- FYI these are put in:
                            -- *** ~/.local/share/nvim/site/parser
                            --
                            -- TODO do I need any of these?
                            -- optional entries (from nvim-treesitter docs: https://github.com/nvim-treesitter/nvim-treesitter#adding-custom-languages)
                            -- location = 'parser', -- only needed if the parser is in subdirectory of a "monorepo"
                            -- generate = true, -- only needed if repo does not contain pre-generated `src/parser.c`
                            -- generate_from_json = false, -- only needed if repo does not contain `src/grammar.json` either
                            -- queries = 'queries/neovim', -- also install queries from given directory
                        },
                    }
                end
            })
        end,
    },


    -- {
    --     -- TODO to use this again, comment out your own registration of the grammar and filetype and then your queries will override this IIAC
    --
    --     -- adds *.test filetype support for test/corpus/*.test files in treesitter grammar repos
    --     --   injects language specified in :language(foo) into (input) node/section
    --     --   injects its own grammar in the (output) node... I was thinking make (output) query type and tie it to a given parser
    --     --   TODO => would be nice to get Coc/vim.lsp completions to tie into injected languages
    --     --      so I could get snippets
    --     --      and other completions (i.e. ts_query_ls language server)
    --
    --     "tree-sitter-grammars/tree-sitter-test",
    --     build = "mkdir parser && tree-sitter build -o parser/test.so",
    --     ft = "test",
    --     init = function()
    --         -- toggle full-width rules for test separators
    --         vim.g.tstest_fullwidth_rules = false
    --         -- set the highlight group of the rules
    --         vim.g.tstest_rule_hlgroup = "FoldColumn"
    --     end
    -- },

    -- FYI :Inspect breaks down highlights into: Treesitter, Syntax, Extmarks... very useful
    -- -- nvim has :Inspect, :InspectTree (:TSPlayground), :EditQuery (nvim 0.10) builtin now
    -- {
    --     'nvim-treesitter/playground',
    --     dependencies = {
    --         { 'nvim-treesitter/nvim-treesitter' },
    --     },
    --     cmd = {
    --         'TSPlaygroundToggle',
    --         'TSHighlightCapturesUnderCursor',
    --     }, -- lazy load on command used
    --     config = function()
    --         require('nvim-treesitter.configs').setup()
    --     end
    -- },

    -- {
    --     -- highlight word under cursor, other occurrences
    --     -- FYI I wrote my own version of this g0t4/illuminate.nvim
    --     enabled = false, -- comment out to enable
    --     "RRethy/vim-illuminate",
    --     event = "CursorHold",
    --     dependencies = {
    --         { 'nvim-treesitter/nvim-treesitter' },
    --     },
    --     -- FYI alt+p works (next match), and alt+n should do next but is swallowed by nvim/iterm2, also alt+i in visual should work as a text object for selection but doesn't work which is fine as `iw`/`iW` works fine
    --     -- config = function()
    --     --     require("illuminate").configure({
    --     --         -- under_cursor = false -- not the current word, only other matches
    --     --     })
    --     -- end,
    --     -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column (several providers actually: treesitter, LSP, regex by default)
    --     --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
    --     --    customizing:
    --     --      hi def IlluminatedWordText gui=underline
    --     --      hi def IlluminatedWordRead gui=underline
    --     --      hi def IlluminatedWordWrite gui=underline
    -- },

}
