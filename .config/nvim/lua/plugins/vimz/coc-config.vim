" *** FYI coc.nvim doesn't modify key-mappings nor vim options, hence the need to specify config explicitly, fine by me!

" FYI see coc-settings for manually added LSPs like for fish
" TODO try other coc extensions / manual LSP registrations...
" TODO and vet this list too
let g:coc_global_extensions = [
            \ 'coc-clangd',
            \ 'coc-css',
            \ 'coc-docker',
            \ 'coc-html',
            \ 'coc-json',
            \ 'coc-lua',
            \ 'coc-pyright',
            \ 'coc-toml',
            \ 'coc-tsserver',
            \ 'coc-vimlsp',
            \ 'coc-xml',
            \ 'coc-yaml',
            \ 'coc-zig',
            \ ]
            "\ 'coc-rust-analyzer',
            "\ 'coc-lightbulb', " seemed to show up on every line regardless if any code actions available => TODO investigate?
    " FYI coc-calc shows the range of what can be done... "1 + 2 = " and it suggests the result "3"
    " PRN https://github.com/iamcco/coc-diagnostic => generic integration of diagnostics tools (make LSP adapter for them, IIUC)
    " brew install zig zls " also consider https://github.com/ziglang/zig.vim
    "\ 'coc-snippets', " TODO investigate .. probably just want copilot completions alone

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

" FYI not using tab to trigger completion:
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


" FYI some keymaps in coc.vim: ~/.local/share/nvim/lazy/coc.nvim/plugin/coc.vim line 723
" page up/down for coc hover windows/menus
" coc#pum is for completions [p]op[u]p [m]enu
"   #visible()
" FYI for testing, in insert mode, in lua, type `vim.o` and you have multiple pages of completions to scroll up/down
" FYI, scroll(1) is down a page, scroll(0) is up a page
" PRN could I wire up neoscroll on this too?! use next/prev if I can get page size? then I could as it has custom funcs IIRC to do other scrolls
"inoremap <silent><expr> <PageDown> coc#pum#visible() ? coc#pum#scroll(1) : "\<PageDown>"
"inoremap <silent><expr> <PageUp> coc#pum#visible() ? coc#pum#scroll(0) : "\<PageUp>"
"
" coc#float is for hover docs
" #has_scroll() and has_float() are available to check if it is visible/scrollable
" FYI    :echo coc#float#has_scroll() " returns 1 if visible, 0 if not
nnoremap <silent><expr> <PageDown> coc#float#has_scroll() ? coc#float#scroll(1) : "\<PageDown>"
nnoremap <silent><expr> <PageUp> coc#float#has_scroll() ? coc#float#scroll(0) : "\<PageUp>"



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
" TODO what to use for gi/gr since those are builtins? just replace them?
nmap <silent> <leader>gi <Plug>(coc-implementation)
nmap <silent> <leader>gr <Plug>(coc-references)
nmap <silent> <F12> <Plug>(coc-definition) " vscode
nmap <silent> <S-F12> <Plug>(coc-references) " vscode

" Use K to show documentation in preview window (I have F1 for help pages)
" FYI K (shift+k) normally maps to man/help pages
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

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
"
" My formatting additions:
xmap <S-M-f> <Plug>(coc-format-selected)
imap <S-M-f> <Esc>:call CocAction('format')<CR>a
nmap <S-M-f> :call CocAction('format')<CR>

augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s)
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying code actions to the selected code block
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying code actions at the cursor position
nmap <leader>ac  <Plug>(coc-codeaction-cursor)
" Remap keys for apply code actions affect whole buffer
nmap <leader>as  <Plug>(coc-codeaction-source)
" Apply the most preferred quickfix action to fix diagnostic on the current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Remap keys for applying refactor code actions
nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)

" Run the Code Lens action on the current line
nmap <leader>cl  <Plug>(coc-codelens-action)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> to scroll float windows/popups
if has('nvim-0.4.0') || has('patch-8.2.0750')
    nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
    inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
    inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
    vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges
" Requires 'textDocument/selectionRange' support of language server
" TODO fix this interferes with my ctrl-S save keymap
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline
"set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
