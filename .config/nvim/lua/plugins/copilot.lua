local use_ai = {
    -- "avante",
    -- "copilot",
    -- "tabnine",
    -- "supermaven",
    "llm.nvim",
}
-- ! consider https://github.com/zbirenbaum/copilot.lua
--    purportedly faster and less glitchy than copilot.vim
--    has panel too with completion preview, is that useful?

local ns_id = vim.api.nvim_create_namespace("line_highlight")


vim.cmd("highlight MySuggestion gui=italic guifg=#DDD")
vim.cmd("autocmd CursorMoved * lua ShowSuggestion()")
function ShowSuggestion()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    vim.api.nvim_buf_set_extmark(0, ns_id, line, 0, {
        end_row = line + 1,
        -- hl_group = "MySuggestion",
        virt_text = {{"suck a dick", "MySuggestion" }}
    })
end

-- vim.cmd("highlight MyHighlightLine gui=underline guibg=#ee9090 guifg=#282828")
-- vim.cmd("autocmd CursorMoved * lua HighlightLine()")
-- function HighlightLine()
--     local line = vim.api.nvim_win_get_cursor(0)[1] - 1
--     vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
--     vim.api.nvim_buf_set_extmark(0, ns_id, line, 0, {
--         end_row = line + 1,
--         hl_group = "MyHighlightLine"
--     })
-- end



-- *** local autocompletion plugin candidates:
-- only focus is inline completions as I can open a chat window on my own should I need that (in a browser, or in nvim)
--
-- - TODO llm.nvim
--    *** YAY ollama backend supported (ollama's api/generate ... and via OpenAI API endpoint too!)
--
--     - https://github.com/huggingface/llm.nvim?tab=readme-ov-file#ollama
--   - uses llm-ls backend (very cool, a language server... much like supermaven does... makes a ton of sense to let it acess entire codebase predictably and not just one off requests w/o the ability to bring in context)
--     - https://github.com/huggingface/llm-ls
--   - looks promising (specifically says alternative to copilot.vim/tabnine-nvim)
--   - formerly hfcc.nvim
--   https://github.com/huggingface/llm.nvim
local llm_nvim = {
    enabled = vim.tbl_contains(use_ai, "llm.nvim"),
    "huggingface/llm.nvim",
    -- event = "VeryLazy", -- TODO WHEN? buffer enter?
    config = function()
        require("llm").setup({
            -- pros:
            -- cons:
            -- - no partial accept :(... only accept_keymap and dismiss_keymap
            --   - this is also why, if you type part of the suggestion instead... it the refetches the entire same suggestion (often)... bc it has no caching mechanism to know the completion is still what it was before partially accepted
            --   - also doesn't seem to cache completions (but, IIUC ollama may do that?) or a middle tier could do that too
            --   - I can add this and learn how to use extmarks along the way
            -- - issue w/ new lines / tab/indent in python not showing more than one line, also in lua IIUC that is happening (only top level completions show multi line)

            -- full config ref: https://github.com/huggingface/llm.nvim?tab=readme-ov-file#setup
            enable_suggestions_on_startup = true,
            -- debounce_ms = 150, -- good deal, it has debounce

            -- backend = "ollama", -- /api/generate
            backend = "ollama", -- /v1/complete # why not /chat/completions!?
            -- BOTH working with codellama/starcoder2 ...
            --

            -- *** llm-ls troubleshooting
            --
            --   mitmproxy --mode=local:"/Users/wesdemos/.local/share/nvim/llm_nvim/bin/llm-ls-aarch64-apple-darwin-0.5.3"
            --
            --   PROXY to capture requests so I can confirm what llm-ls is doing and I fixed it!
            --   also mapped to remote ollama instance (localhost wasn't capturing, not surprising...)... I should've done 192.168.1.X with my IP to get it , derp below
            --
            -- llm-ls logs
            --   ~/.cache/llm_ls/llm-ls.log
            --   these logs were nearly useless.. on erorrs, barely anything is logged and it's just like "derp fail"
            --

            -- PRN TRY huggingface backend and pull model that way, would have many more choices then


            -- Then I sucked a big fat ... and completely missed request_body earlier... to literally modify the http request for completion (if ollama backend => /api/generate, if openai => /v1/completions)
            -- !!! DO NOT TEST COMPLETIONS with the below tokens config.... fux it all up, lol
            request_body = {
                -- *** THIS WILL DIFFER PER BACKEND!!!
                -- right now this is for ollama backend:
                -- https://github.com/abetlen/llama-cpp-python?tab=readme-ov-file#openai-compatible-web-server
                raw = true, -- set this b/c llm.nvim is litearlly building the entire prompt (do not use template)
                -- PRN CONSIDER:
                --     temperature = 0.2,
                --     top_p = 0.95,
                options = {
                    -- https://github.com/ollama/ollama/blob/main/docs/api.md - api docs for api/generate, including options and links to
                    -- https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
                    num_predict = 40,
                    -- HOLY CRAP this is FAST at 4... and it was half a line in some cases... so maybe set this low? if I only get one line at a time...  ... otherwise IIUC its infinite or up to the modelfile/ model limits!
                    -- WOULD be nice to have a short/long completions mode to toggle how long I allow
                },
            },
            -- DOES THIS HAVE streaming support? I suspect not... hrm doesn't matter, can still try it like you used vscode-CodeGPT ext... which worked well enough you just have to set expectations that you are only testing quality of suggestions (not speed, yet)
            --  I CAN CONFIRM COMPLETIONS ARE GOOD (quality)...

            -- TODO is it sometimes not showing multiple lines when there are several and it only shows first? I felt like that might have happened in the python tests I tried... is it a whitespace problem?
            --  YUP JUST CONFIRMED... WTF? look at suggests repo and add subtract tests
            --  BUT PREVIOUSLY I SAW multiple suggestions showing in lua code files...
            --  and it sucks that it its taking longer to generate 10 lines of suggestion and then only showing me the first one!! :(

            -- *** qwen2.5
            model = "qwen2.5-coder:3b", -- scrappy but if I give right context it is much faster and still accurate (i.e. paste in ref files list when completing require calls in lazy setup)
            -- model = "qwen2.5-coder:14b",
            -- run ollama serve in debug mode... look at output when model is first loaded, IIAC this is what I need
            -- llm_load_print_meta: general.name     = Qwen2.5 Coder 3B Instruct
            -- llm_load_print_meta: BOS token        = 1516c43 '<|endoftext|>'
            -- llm_load_print_meta: EOS token        = 151645 '<|im_end|>'
            -- llm_load_print_meta: EOT token        = 151645 '<|im_end|>'
            -- llm_load_print_meta: PAD token        = 151643 '<|endoftext|>'
            -- llm_load_print_meta: LF token         = 148848 'ÄĬ'
            -- llm_load_print_meta: FIM PRE token    = 151659 '<|fim_prefix|>'
            -- llm_load_print_meta: FIM SUF token    = 151661 '<|fim_suffix|>'
            -- llm_load_print_meta: FIM MID token    = 151660 '<|fim_middle|>'
            -- llm_load_print_meta: FIM PAD token    = 151662 '<|fim_pad|>'
            -- llm_load_print_meta: FIM REP token    = 151663 '<|repo_name|>'
            -- llm_load_print_meta: FIM SEP token    = 151664 '<|file_sep|>'
            -- llm_load_print_meta: EOG token        = 151643 '<|endoftext|>'
            -- llm_load_print_meta: EOG token        = 151645 '<|im_end|>'
            -- llm_load_print_meta: EOG token        = 151662 '<|fim_pad|>'
            -- llm_load_print_meta: EOG token        = 151663 '<|repo_name|>'
            -- llm_load_print_meta: EOG token        = 151664 '<|file_sep|>'
            -- llm_load_print_meta: max token length = 256
            -- FAST RESPONSES... so if I can fix token params this is gonna be what I want (faster than even CodeGPT used this same model)
            tokens_to_clear = { "<|endoftext|>" },
            fim = {
                enabled = true,
                prefix = "<|fim_prefix|>",
                middle = "<|fim_middle|>",
                suffix = "<|fim_suffix|>",
            },
            -- context_window = 1024, -- 4096,
            -- -- tokenizer = {
            -- --     repository = "codellama/CodeLlama-13b-hf",
            -- -- },
            -- -- END codellamaj
            -- FYI I get completions that summarize this file!!! wow.. cool... and it tells me about each plugin... that is at least not noise
            -- OK AND LOOK IN THE ollama logs... shows request made... and I can see how it filled out the template! GOOD ... now, is this right? it seems to be not doing what I want with code completion...  smth with fim is not quite what it expected... are those wrong?




            -- -- START codellama model = "codellama", -- TODO try this one too
            -- -- model = "codellama/CodeLlama-13b-hf",
            -- -- TODO double check this params... I am not getting predictable completions yet
            -- --
            -- model = "codellama", -- ollama variant of codellama doesnot list FIM tokens
            -- tokens_to_clear = { "<EOT>" },
            -- fim = {
            --     enabled = true,
            --     prefix = "<PRE> ",
            --     middle = " <MID>",
            --     suffix = " <SUF>",
            -- },
            -- context_window = 1024, -- 4096,
            -- -- tokenizer = {
            -- --     repository = "codellama/CodeLlama-13b-hf",
            -- -- },
            -- -- END codellama

            -- -- *** TRY starcoder
            -- -- https://ollama.com/library/starcoder2
            -- -- use config example in repo https://github.com/huggingface/llm.nvim?tab=readme-ov-file#starcoder
            -- tokens_to_clear = { "<|endoftext|>" },
            -- fim = {
            --     enabled = true,
            --     prefix = "<fim_prefix>",
            --     middle = "<fim_middle>",
            --     suffix = "<fim_suffix>",
            -- },
            -- model = "starcoder2", -- RESULTS COME BACK FAST... but never show... codellama much slower than starcoder so at least troubleshoot with this... can I log the response from ollama?
            -- -- model = "bigcode/starcoder",
            -- context_window = 8192,
            -- -- tokenizer = {
            -- --   repository = "bigcode/starcoder",
            -- -- }
            -- --




            -- TODO if it works, try all sorts of models (you've never tested any of them for this use case!)
            url = "http://build21.lan:11434", -- llm-ls uses "/v1/completions"
            -- url = "http://localhost:11434",

        })
    end
}
--
--
-- - https://github.com/tzachar/cmp-ai
--   sounds like it has on-demand or all the time completions... and mentions qwen so it should work
--   only concern, is it previewed in a dropdown like coc? or is it inline grayed out text like copilot/supermaven?
--      yuck, emphasis is on pretty print in completion menus... YUCK..
--      THAT SAID, are there any plugins to nvim-cmp that take the first suggestion and show it inline? like copilot/supermaven? I wouldn't care as long as I can prioritize model suggestions over all others
--         ASIDE... curious, does COC have a way to preview first completion inline (but, only if no supermaven avail)?
--   also I use coc so this is gonna conflict, but I do use cmp for cmdline completions so this isn't gonna be absolutely terrrible... I even had some keys mapped for using nvim-cmp in buffers (though I would need to flesh that out and migrate my LSP settings => cocsettings, etc)
--   debounce is not part of the plugin... and it likley should go into nvim-cmp...
--      https://www.reddit.com/r/neovim/comments/18lxe4a/comment/ke1jf1f/
--      another issue as yeah... can't fire off 100 requests (even if canceled) in a row... and why?!
--      throttle is not debounce
-- - https://github.com/fauxpilot/fauxpilot
--    - works w/ vscode too.. swap in ollama there... interesting
--    - allegely works w/ copilot.nvim and can map requests to ollama... that said its docs are not reassuring.. insane tech stack setup with docker/nvidida-containers and ... I just want to config an API.. I don't want smth else loading/importing models... etc
-- - ROLL MY OWN
--    - how hard is it? to just debounce the mouse... .request completions (w/ cancelation on prev)... and hardest part has to be extmarks to show it but is that that difficult?
--    - how is this not already conquered?!
--       - ok TBH... supermaven does what I want... (minus I'd like to see jump edits)
--    - I could impl jump edits with my own :)
--
-- - vscode ollama notes:
--    - btw ChatGPT vscode plugin did work in vscode... but it was not fun to configure it and didn't have streaming either (not AFAICT)
--      - it did work nicely with gwen2.5-coder:3b
--      - this is what made me want to see what is avail in nvim... so I can see if I like qwen2.5 in nvim too
--
-- Seprate notes:
--   - investigate GPU/CPU usage for models... is ollama utilizing GPU for the models I run this for... that could explain the issue I had with bigger models not running even if there is room on GPU still:
--      if it isn't, consider using llama.cpp directly to force it : https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
--
--
--

function SwitchCopilot()
    -- TODO I should call this in config of preferred copilot OR ...  setup one to be disabled out of the gate and other to be enabled in the opts for each
    -- FYI supermaven toggle works across vim restarts, copilot is per buffer IIUC
    local supermavenapi = require("supermaven-nvim.api")
    if supermavenapi.is_running() then
        supermavenapi.stop()
        if vim.fn.exists("*copilot#Enabled") then
            vim.cmd("Copilot enable")
        end
    else
        supermavenapi.start()
        if vim.fn.exists("*copilot#Enabled") then
            vim.cmd("Copilot disable")
        end
    end
end

local avante =
{
    enabled = vim.tbl_contains(use_ai, "avante"),
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change

    -- config docs: https://github.com/yetone/avante.nvim?tab=readme-ov-file#default-setup-configuration
    opts = {
        -- FYI defaults to claude, recommends claude too.. I should try both
        provider = "copilot",
        -- auto_suggestions_provider = "claude" -- or "copilot" or? which is better try both
        behaviour = {
            auto_suggestions = false, -- Experimental stage
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = false,
            support_paste_from_clipboard = false,
        },
    },

    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim", -- for vim.ui.select
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim", -- ui component library
        --- The below dependencies are optional,
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua", -- for providers='copilot'
        {
            -- support for image pasting (FOR REAL?)
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                -- recommended settings
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    -- required for Windows users
                    use_absolute_path = true,
                },
            },
        },
        {
            -- TODO do I wanna keep this? I'm pretty happy with just onedarkpro + darker bg... looks great
            -- TODO use this w/o avante too?
            -- cons:
            --   - alignment is off when switching to insert mode b/c normal mode formats different (i.e. lists)
            --
            -- Make sure to set this up properly if you have lazy=true
            'MeanderingProgrammer/render-markdown.nvim',
            opts = {
                file_types = { "markdown", "Avante" },
            },
            ft = { "markdown", "Avante" },
        },
    },
}

-- avante requires 0.10+
local version = vim.version()
if version.major == 0 and version.minor < 10 then
    avante = {}
end

return {
    llm_nvim,

    {
        "g0t4/ask-openai.nvim",
        event = { "CmdlineEnter" },
        dir = "~/repos/github/g0t4/ask-openai.nvim",

        -- *** copilot (default):
        opts = {
            -- verbose = true,
        },

        -- *** OpenAI + keychain:
        -- opts = {
        --     provider = function()
        --         return require("ask-openai.config")
        --             .get_key_from_stdout("security find-generic-password -s openai -a ask -w")
        --     end,
        --     -- verbose = true,
        -- },

        -- *** GROQ + keychain:
        -- opts = {
        --     -- model = "llama-3.1-70b-versatile",
        --     model = "llama-3.2-90b-text-preview",
        --     use_api_groq = true, -- easier
        --     -- api_url = "https://api.groq.com/openai/v1/chat/completions", -- if not standard
        --     provider = function()
        --         return require("ask-openai.config")
        --             .get_key_from_stdout("security find-generic-password -s groq -a ask -w")
        --     end,
        --     -- verbose = true,
        -- },

        -- *** ollama:
        -- opts = {
        --     provider = "keyless",
        --     model = "llama3.2-vision:11b", -- ollama list
        --     use_api_ollama = true,
        -- },

        dependencies = {
            "nvim-lua/plenary.nvim",
        }
    },

    {
        -- TODO sign up for a trial and try the full deal, starter version is just useless (completes like two words at a time)
        enabled = vim.tbl_contains(use_ai, "tabnine"),
        "codota/tabnine-nvim",
        build = "./dl_binaries.sh",
        config = function()
            require('tabnine').setup({
                disable_auto_comment = true,
                accept_keymap = "<Tab>",
                dismiss_keymap = "<C-]>",
                debounce_ms = 800,
                suggestion_color = { gui = "#808080", cterm = 244 },
                exclude_filetypes = { "TelescopePrompt", "NvimTree" },
                log_file_path = nil, -- absolute path to Tabnine log file
                ignore_certificate_errors = false,
            })
        end
        -- AND/OR :CocInstall coc-tabnine
        -- https://github.com/tabnine/coc-tabnine
    },

    {
        enabled = vim.tbl_contains(use_ai, "supermaven"),
        "supermaven-inc/supermaven-nvim",
        config = function()
            -- FYI supermaven wont work in a buffer that doesn't have an actual file, IIUC from log errors when renaming a file in a filetype=DressingInput inside Nvim-Tree panel (on rename command)... hrm that stinks
            -- TODO investigate why fill-in-the-middle completions show at the end of the line (lua, py confirmed) => probably smth with my config: https://github.com/supermaven-inc/supermaven-nvim/issues/66#issuecomment-2221721242
            --   NBD honestly just wanna keep my eye on a fix if possible it would be nice to see what is/isn't changing before accept!
            require("supermaven-nvim").setup {
                -- disable_inline_completion = true, -- use w/ nvim-cmp
                keymaps = {
                    -- accept_suggestion = "<Tab>", -- all copilots use this, also doesn't apply if no suggestion shown (obviously)
                    -- clear_suggestion = "<C-]>", -- all copilots use this
                    accept_word = "<M-Right>", -- <C-j> is default
                },
                color = {
                    -- MUST SET a color to get SupermavenSuggestion highlight group to work, else won't exist
                    suggestion_color = "#ffffff",
                    cterm = 244,
                }
            }

            local function override_suggestion_color()
                -- FYI color options only allow setting a foreground color, hence the following to set any aspect I want
                -- SupermavenSuggestion is set on VimEnter/ColorScheme, so create a new augroup to override it b/c this happens after the supermaven augroup events run
                -- vim.api.nvim_create_augroup("supermaven2", { clear = true }) -- if use diff augroup then create it here, else append to supermaven augroup commands:
                vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
                    group = "supermaven", -- TLDR: append autocmd that sets color and b/c its last, it wins
                    pattern = "*",
                    callback = function()
                        local group_name = require("supermaven-nvim.completion_preview").suggestion_group
                        -- FYI was SupermavenSuggestion last I checked, use name just in case it changes?!
                        -- TODO - set my own suggestion group name on init? so I don't need an autocmd to ensure this style wins? https://github.com/supermaven-inc/supermaven-nvim/issues/49
                        vim.api.nvim_set_hl(0, group_name, {
                            -- FYI force not needed currently, leaving as reminder
                            -- fg = "#ff0000", force = true, bold = true, underline = true
                            -- fg = "#6d6a94", underline = true -- purpleish gray
                            -- fg = "#4b7266", underline = true -- green
                            -- fg = "#CCCCCC", underline = true -- dimmed white
                            fg = "#ffffff",
                            italic = true,
                            underline = true -- white
                        })
                    end,
                })
            end

            override_suggestion_color()

            function GetStatusLineSupermaven()
                -- test with: :SupermavenToggle
                -- OK so if this function exists that means supermaven plugin is loaded, so no need to check beyond that, check for the existence of this func when using it (i.e. in statusline, and lualine will silently ignore a missing func)
                local api = require("supermaven-nvim.api") -- https://github.com/supermaven-inc/supermaven-nvim/tree/main#lua-api
                if api.is_running() then
                    return " " -- add space after too
                end
                return " " -- add space after icon so subsequent text doesn't run under it
            end

            -- TODO... if I wanna toggle copilots, write one func to toggle the active one and set up one keymap for it across all copilots, like I did with lualine StatusLine_WrapCopilotStatus
            vim.keymap.set('n', '<F13>', ':SupermavenToggle<CR>')
            vim.keymap.set('i', '<F13>', '<Esc>:SupermavenToggle<CR>a')
        end
    },

    {
        enabled = vim.tbl_contains(use_ai, "copilot"),
        'github/copilot.vim',
        -- event = { "InsertEnter" }, -- lazy load on first insert  -- load immediately is fine, esp if changing status bar here
        config = function()
            vim.cmd [[

                "let g:copilot_filetypes = {
                "    \ '*': v:true,
                "    \ }

                "" copilot consider map to ctrl+enter instead of tab so IIUC other completions still work, O
                "imap <silent><script><expr> <C-CR> copilot#Accept("\\<CR>")
                "let g:copilot_no_tab_map = 1
                "" ok I kinda like ctrl+enter for copilot suggestions (vs enter for completions in general (coc)) but for now I will put tab back and see if I have any issues with it and swap this back in if so

                " statusline BEFORE lualine added
                "set statusline=%f\ %y\ %m\ %=%{GetStatusLineCopilot()}\ L:%l/C:%c\ %p%%

                function! GetStatusLineCopilot()
                    " exists is just in case I move this elsewhere and I cant know for sure the copilot plugin is loaded already
                    if exists('*copilot#Enabled') && copilot#Enabled()
                        " add spaces after icon so subsequent text doesn't run under it
                        "return nr2char(0xEC1E)
                        return ' '
                    else
                        "return nr2char(0xF4B9)
                        return ' '
                    endif
                    " glyphs:
                    "   \uEC1E
                    "   \uF4B8
                    "   \uF4B9
                    "   \uF4BA
                endfunction

                function! ToggleCopilot()
                    " FYI https://github.com/github/copilot.vim/blob/release/autoload/copilot.vim
                    " FYI only global toggle, not toggling buffer local
                    " PRN save across sessions? maybe modify a file that is read on startup (not this file, I want it out of vimrc)
                    if copilot#Enabled()
                        Copilot disable
                    else
                        Copilot enable
                    endif
                    " Copilot status " visual confirmation - precise about global vs buffer local too
                endfunction
                :inoremap <F13> <Esc>:call ToggleCopilot()<CR>a
                " :inoremap <F13> <C-o>:call ToggleCopilot()<CR> " on empty, indented line, causes cursor to revert to start of line afterwards
                :nnoremap <F13> :call ToggleCopilot()<CR>

            ]]

            -- TODO why is this not winning when use autocmd (do I need a group, TBD, copilot help didn't mention it)
            -- vim.api.nvim_create_autocmd('ColorScheme', {
            --     pattern = '*',
            --     -- group = "...",
            --     callback = function()
            vim.api.nvim_set_hl(0, 'CopilotSuggestion', {
                fg = '#ff0000',
                -- ctermfg = 8,
                force = true,
            })
            -- end
            -- })
        end,
    },
    avante,
}


-- DECIDED NO
-- {
--     -- NOT A GOOD FIT: completions aren't automatic AND cannot use custom models (let alone not openai models)
--          completions are designed more like prompting for help on a chunk of code and then waiting
--          ALSO, results are NOT STREAMED... deal breaker too (I want a responsive Ux and that includes, if possible, streaming results, so I can start reviewing and not just wait, esp for local models that take more time to get full completion)
--
--
--     enabled = vim.tbl_contains(use_ai, "ChatGPT.nvim"),
--     "jackMort/ChatGPT.nvim",
--     config = function()
--         -- BTW uses curl under the hood, super accessible plugin code
--         -- pros:
--         -- - actions concept => configure model per "action" (scenario)... also tweak params, etc - builtin actions + custom
--         -- - interactive/float window => I like the iteration idea where you have it gen some code, then you can take it and prompt more changes to it, good workflow for focusing on a new chunk of code
--         --   - https://youtu.be/dWe01EV0q3Q?t=40
--         -- improves (submit PRs, if I like using this):
--         -- - needs checkhealth provider to dump info
--         -- - docs should include non-OpenAI (ie ollama) config example
--         -- cons:
--         -- - have to trigger inline completions with a keymap... not in advance...
--         --   - deal breaker as I just wanted an altenrative for running my own completions model to see how it feels
--         --   - and doesn't have a way to change the model for completions, its hardcoded (lua/chatgpt/flows/code_completions/init.lua)
--         --     - using this with qwen2.5-coder:3b was disastrous (took forever and just generated repetative code :)... would need prompt changd for qwen
--         -- - no global default model, IIUC has to be set per action (b/c actions default to set models) - not end of world
--         --   - not at all clear if I need to put models for actions into a new actions file OR if it can go into this config below?
--         -- - action for complete_code is doing weird stuff...
--         -- outstanding to figure out:
--         --   understand actions.json and how to override that (I just modified the lazy plugin repo checkout to swap values)
--         require('chatgpt').setup({
--             verbose = true, -- TODO ADD to API
--             -- cool uses nested commands, makes sense... but is that gonna hurt latency to run these every time (or are they cached?)
--             -- ms matters with completions, I wouldn't wanna add 40ms in lookup commands
--             --  security find-* -w => 57ms ! yikez
--             api_host_cmd = 'echo -n http://localhost:11434',
--             api_key_cmd = 'echo -n foo',
--             -- api_key_cmd = 'security -s openai -a ask -w'
--             openai_params = {
--                 model = "qwen2.5-coder:3b"
--             }
--         })
--     end,
--     dependencies = {
--         "MunifTanjim/nui.nvim",
--         "nvim-lua/plenary.nvim",
--         -- "folke/trouble.nvim", -- optional -- TODO DO I WANT THIS?
--         "nvim-telescope/telescope.nvim"
--     }
-- },
