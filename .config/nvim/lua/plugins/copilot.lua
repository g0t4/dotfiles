local avante =
{
    enabled = false,
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
        "stevearc/dressing.nvim",      -- for vim.ui.select
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",        -- ui component library
        --- The below dependencies are optional,
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua",      -- for providers='copilot'
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

    {
        enabled = true,
        "supermaven-inc/supermaven-nvim",
        config = function()
            require("supermaven-nvim").setup {
                keymaps = {
                    -- -- defaults:
                    -- accept_suggestion = "<Tab>",
                    -- clear_suggestion = "<C-]>",
                    -- accept_word = "<C-j>",
                }

            }
        end,
    },

    {
        enabled = false,
        'github/copilot.vim',
        -- event = { "InsertEnter" }, -- lazy load on first insert  -- load immediately is fine, esp if changing status bar here
        config = function()
            vim.cmd([[
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

                :inoremap <F12> <Esc>:call ToggleCopilot()<CR>a
                " :inoremap <F12> <C-o>:call ToggleCopilot()<CR> " on empty, indented line, causes cursor to revert to start of line afterwards
                :nnoremap <F12> :call ToggleCopilot()<CR>

            ]])
        end,
    },
    avante,
}
