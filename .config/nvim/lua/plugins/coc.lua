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
            vim.cmd([[
                " *** FYI coc.nvim doesn't modify key-mappings nor vim options, hence the need to specify config explicitly, fine by me!

                " FYI
                "  :CocList extensions  " and others
                "  :CocInstall coc-lua   " wow gutter icons showed right up!
                "     https://github.com/josa42/coc-lua
                "     https://github.com/LuaLS/lua-language-server  # LSP backend, use this for options (ie diagnostics config)
                "  :CocInstall coc-vimlsp
                "     https://github.com/iamcco/vim-language-server
                "  :CocInstall coc-fish " shows man pages on Shift+K!! cool
                "  :CocInstall coc-pyright
                "  :CocInstall coc-toml coc-yaml coc-json
                "  :CocInstall coc-svg
                "  :CocInstall coc-docker
                "
                " TRY:
                "   list here: https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions#implemented-coc-extensions
                "   ??? https://github.com/yuki-yano/coc-copilot
                "   ??? https://github.com/neoclide/coc-tabnine
                "   coc-sh (bash)   coc-powershell
                "   coc-omnisharp (c#,vb)
                "   coc-nginx
                "   coc-rust-analyzer?
                "   coc-tsserver (typescript, javascript)
                "   lua alternative: https://github.com/xiyaowong/coc-sumneko-lua
                "   mardownlint / markdown-preview-enhanced / markmap (mindmap + markdown)
                "   spelling: coc-ltex / coc-spell-checker

                " Some servers have issues with backup files, see #649
                set nobackup
                set nowritebackup

                " Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
                " delays and poor user experience
                set updatetime=300

                " Always show the signcolumn, otherwise it would shift the text each time
                " diagnostics appear/become resolved
                set signcolumn=yes

                "" Use tab for trigger completion with characters ahead and navigate
                "" NOTE: There's always complete item selected by default, you may want to enable
                "" no select by `"suggest.noselect": true` in your configuration file
                "" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
                "" other plugin before putting this into your config
                "inoremap <silent><expr> <TAB>
                "      \ coc#pum#visible() ? coc#pum#next(1) :
                "      \ CheckBackspace() ? "\<Tab>" :
                "      \ coc#refresh()
                "inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

                " Make <CR> to accept selected completion item or notify coc.nvim to format
                " <C-g>u breaks current undo, please make your own choice
                inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

                function! CheckBackspace() abort
                  let col = col('.') - 1
                  return !col || getline('.')[col - 1]  =~# '\s'
                endfunction

                " Use <c-space> to trigger completion
                if has('nvim')
                  inoremap <silent><expr> <c-space> coc#refresh()
                else
                  inoremap <silent><expr> <c-@> coc#refresh()
                endif

                " TODO try out diagnostics
                " Use `[g` and `]g` to navigate diagnostics
                " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
                nmap <silent> [g <Plug>(coc-diagnostic-prev)
                nmap <silent> ]g <Plug>(coc-diagnostic-next)

                " TODO try out navigation
                " GoTo code navigation
                nmap <silent> gd <Plug>(coc-definition)
                nmap <silent> gy <Plug>(coc-type-definition)
                nmap <silent> gi <Plug>(coc-implementation)
                nmap <silent> gr <Plug>(coc-references)

                " Use K to show documentation in preview window
                nnoremap <silent> K :call ShowDocumentation()<CR>

                function! ShowDocumentation()
                  if CocAction('hasProvider', 'hover')
                    call CocActionAsync('doHover')
                  else
                    call feedkeys('K', 'in')
                  endif
                endfunction


                " disabled for now, multiline strings in lua aren't recognized as nested code which makes sense... so any time cursor stops in the multiline string it higlights all of it (yuck)
                " Highlight the symbol and its references when holding the cursor
                "autocmd CursorHold * silent call CocActionAsync('highlight')

            ]])

            -- !!! TODO move to lazy load on keys/commands? and filetypes or? take some time to look into this when you get back to looking into coc again

            vim.keymap.set('n', '<S-M-f>', ":call CocAction('format')<CR>", { desc = 'Coc format (normal mode)' }) -- vscode format call...can this handle selection only?
            vim.keymap.set('i', '<S-M-f>', "<Esc>:call CocAction('format')<CR>a", { desc = 'Coc format (insert mode)' })
            -- TODO vim freezes when I use this for local a below
            -- rename:
            vim.keymap.set('n', 'C-r,C-r', ":call CocAction('rename')<CR>", { desc = 'Coc rename' })

            -- TODO review lua config for many other code action helpers... I skipped most for now

            -- Add `:Format` command to format current buffer
            vim.api.nvim_create_user_command("Format", "call CocAction('format')", {})

            -- " Add `:Fold` command to fold current buffer
            vim.api.nvim_create_user_command("Fold", "call CocAction('fold', <f-args>)", { nargs = '?' })

            -- Add `:OR` command for organize imports of the current buffer
            vim.api.nvim_create_user_command("OR", "call CocActionAsync('runCommand', 'editor.action.organizeImport')",
                {})
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
