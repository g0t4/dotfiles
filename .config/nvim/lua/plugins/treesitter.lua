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
            -- - well worth the time to read `:help treesitter-highlight` to learn what nvim covers
            -- - nvim-treesitter does these things over builtin nvim treesitter support:
            --   - install parsers by compiling them using tree-sitter-cli
            --   - additional features beyon highlighting that nvim does:
            --     - folding,
            --     - TODO list others and see what changed in v0.12
            --     - textobjects 'nvim-treesitter/nvim-treesitter-textobjects',
            --   - :InspectTree
            -- - :TSModuleInfo is gone now OR am I not setting up nvim-treesitter correctly now?

            -- ok to get highlights to work for my custom parsers:
            -- add parser dir to plugin path so highlights.scm is discoverable
            -- then manually call :=vim.treesitter.start() when window is focused with buffer with harmony/qwen_chatml file is opened
            --   works!
            --   TODO start highlighting when the filetype is opened
            vim.opt.runtimepath:append(vim.fn.expand("~/repos/github/g0t4/tree-sitter-harmony"))
            vim.opt.runtimepath:append(vim.fn.expand("~/repos/github/g0t4/tree-sitter-qwen-chatml"))
            --  verify queries found:
            --  :echo globpath(&rtp, 'queries/qwen_chatml/*', 1, 1)
            --  :echo globpath(&rtp, 'queries/harmony/*', 1, 1)

            --
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
            -- then
            --   TODO one issue, on macOS I built a dylib and wasm... not *.so and nvim-treesitter is building my parsers as *.so...
            --   TODO OR.. let nvim-treesitter do the compile like before (fine by me too)
            --
            -- TODO look into `:h treesitter-language-injections` and see if you can get this to work now! i.e. JSON within harmony tool calls (or XML within Qwen tool calls)

            do return end
            require 'nvim-treesitter.configs'.setup {
                sync_install = false,
                auto_install = true, -- auto install on entering buffer (must have tree-sitter CLI, IIUC)

                -- TODO review other builtin modules/plugins:
                -- - https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins
                --  PRN nvim-treesitter/nvim-treesitter-context	- show context of cursor position (ie function, class, etc) - like vscode scroll context thingy
                --
                -- matchup/matchit
                -- TODO! is matchit builtin good enough? does treesitter version of it use AST instead of smth else in matchit bundled extension?
                -- matchup = {
                --     -- FRIGGIN AWESOME - TODO make a video about this
                --     enable = true, -- enable for treesitter based matching, use keymap: % to jump between matching pairs, i.e. plist (xml) that has hundreds of lines under an element and you are at end and wanna jump up... wows (IIAC folds might help too?)
                --     -- can open AST too and move around (:InspectTree) but dang is it slow on huge xml files
                --     -- PRN any outline mode that would work well too, extension?
                -- },

                highlight = {
                    enable = true, -- doesn't seem to turn it off, is treesitter initilized b/c of some other plugin first and thus my config here isn't applied?
                    -- disable = {},  -- confirmed TSModuleInfo shows X for these languages
                    -- additional_vim_regex_highlighting = true, -- true OR list of languages... I can't get this to change anything with my custom sytnax highlights, maybe this is smth else enable/disable?

                    -- custom_captures = {
                    --   -- IIUC I only need this if I want to link to another existing hl group (ie in a theme)
                    --     ["comment_todo"] = "TodoComment",
                    -- },
                },
                indent = {
                    enable = true,
                    disable = {},
                },
                -- FYI doesn't seem to be a "fold/ing" enable/disable config section
                incremental_selection = {
                    -- similar to Ctrl+W in jetbrains IDEs
                    enable = true,
                    keymaps = {
                        init_selection = 'gnn', -- Start selection
                        node_incremental = 'grn', -- Expand to the next node
                        scope_incremental = 'grc', -- Expand to the next scope
                        node_decremental = 'grm', -- Shrink selection
                    },
                },
            }


            -- * custom grammars (i.e. ones I am hacking on, or not in official sets)
            local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

            parser_config.harmony = {
                install_info = {
                    url = "~/repos/github/g0t4/tree-sitter-harmony",
                    files = { "src/parser.c" },
                    -- queries => use RTP (no magic this way)
                }
            }

            parser_config.qwen_chatml = {
                install_info = {
                    url = "~/repos/github/g0t4/tree-sitter-qwen-chatml",
                    files = { "src/parser.c" },
                    -- generate = true,
                    -- generate_from_json = false,
                    -- queries => use RTP (no magic this way)
                    -- make sure name shows in :TSModuleInfo
                    --   :TSInstall qwen_chatml
                    -- :TSUpdate -- IIUC recompile it when you change it... not sure if it is automatic?
                }
            }

            parser_config.test = {
                install_info = {
                    url = "https://github.com/tree-sitter-grammars/tree-sitter-test",
                    files = { "src/parser.c", "src/scanner.c" },
                },
            }
            parser_config.cst = {
                install_info = {
                    url = "https://github.com/tree-sitter-grammars/tree-sitter-cst",
                    files = { "src/parser.c" },
                },
            }

            -- above will autoinstall, can also uninstall/install again:
            -- :TSInstall harmony
            -- :TSInstallSync harmony -- do I need this on changes to my grammar?
            -- :TSInstall test

            -- TSModuleInfo shows what features (highlight, illuminate[if plugin enabled], indent, incremental_selection), not folding?
        end,
        init   = function()
            -- https://neovim.io/doc/user/fold.html (FYI can use other methods like indent, syntax, manual, etc... for now I will try ts based)
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

            vim.o.foldenable = false -- no autofolding, just manual after open file
        end
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

    {
        -- highlight word under cursor, other occurrences
        enabled = false, -- comment out to enable
        "RRethy/vim-illuminate",
        event = "CursorHold",
        dependencies = {
            { 'nvim-treesitter/nvim-treesitter' },
        },
        -- FYI alt+p works (next match), and alt+n should do next but is swallowed by nvim/iterm2, also alt+i in visual should work as a text object for selection but doesn't work which is fine as `iw`/`iW` works fine
        -- config = function()
        --     require("illuminate").configure({
        --         -- under_cursor = false -- not the current word, only other matches
        --     })
        -- end,
        -- FYI integrates with treesitter! :TSModuleInfo adds illuminate column (several providers actually: treesitter, LSP, regex by default)
        --    can use modes_denylist to hide in visual mode if I wanna use smth else in that mode to highlight selections: https://github.com/RRethy/vim-illuminate/issues/141
        --    customizing:
        --      hi def IlluminatedWordText gui=underline
        --      hi def IlluminatedWordRead gui=underline
        --      hi def IlluminatedWordWrite gui=underline
    },

}
