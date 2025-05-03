" *** FYI coc.nvim doesn't modify key-mappings nor vim options, hence the need to specify config explicitly, fine by me!

" FYI see coc-settings for manually added LSPs like for fish
" TODO try other coc extensions / manual LSP registrations...
" TODO and vet this list too
let g:coc_global_extensions = [
            \ 'coc-clangd',
            \ 'coc-cmake',
            \ 'coc-css',
            \ 'coc-docker',
            \ 'coc-go',
            \ 'coc-html',
            \ 'coc-json',
            \ 'coc-lua',
            \ 'coc-prettier',
            \ 'coc-pyright',
            \ 'coc-rust-analyzer',
            \ 'coc-sh',
            \ 'coc-snippets',
            \ 'coc-sqlfluff',
            \ 'coc-toml',
            \ 'coc-tsserver',
            \ 'coc-vimlsp',
            \ 'coc-xml',
            \ 'coc-yaml',
            \ 'coc-zig',
            \ '@yaegassy/coc-nginx',
            \ ]
            "\ 'coc-rust-analyzer',
            "\ 'coc-lightbulb', " seemed to show up on every line regardless if any code actions available => TODO investigate?
            " \ 'coc-powershell', " WTF the it opens an integrated terminal EVERY TIME AND EVEN IF IT IS DISABLED, it still does it and just closes it .. WTF

    " FYI coc-calc shows the range of what can be done... "1 + 2 = " and it suggests the result "3"
    " PRN https://github.com/iamcco/coc-diagnostic => generic integration of diagnostics tools (make LSP adapter for them, IIUC)
    " brew install zig zls " also consider https://github.com/ziglang/zig.vim
    " BTW prettier formats (graphql, ...)
    " coc-sh (bash)

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
" IOTW <C-g>u ensures you can undo the selection without anything before that
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
            \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" FYI wes added - hide coc to see completions behind it
" FYI <C-e> could be an alternative?
" The else part is to pass through the original keypress <S-CR> and is working fine now
" Might have issues if shift not detected properly so keep an eye on it
" testing: go into insert mode, get pum to open, press Shift-Enter to close it
"    passthru: after closing it just hit Shift-Enter again and it should insert a newline
"    actually I haven't verified if it breaks S-Enter, pass through might just be doing enter ;)
inoremap <silent><nowait><expr> <S-CR> coc#pum#visible() ? coc#pum#cancel() : "<S-CR>"



function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction


" FYI some keymaps in coc.vim: ~/.local/share/nvim/lazy/coc.nvim/plugin/coc.vim line 723
" TODO do I have a race condition on loading plugins that might be causing the defaults to not map?
"    BECAUSE: coc.vim won't set  these if a keymap already exists so that might be it, if so add those back here from coc.vim (above, line 723 etc)
"    OK I have a few not working for LUA maybe only? investigate later, I am leaving the broken ones for now
" *** page up/down for coc hover windows/menus
" coc#pum is for completions [p]op[u]p [m]enu
"   #visible()
" FYI for testing, in insert mode, in lua, type `vim.o` and you have multiple pages of completions to scroll up/down
" FYI, scroll(1) is down a page, scroll(0) is up a page
" PRN could I wire up neoscroll on this too?! use next/prev if I can get page size? then I could as it has custom funcs IIRC to do other scrolls
"   TODO pageup/down doesn't work when pum first opens (push down arrow and then page up/down works?) try in a lua file
"    TODO could it have anything to do with sessions? hrm figure out later
inoremap <silent><expr> <PageDown> coc#pum#visible() ? coc#pum#scroll(1) : "\<PageDown>"
inoremap <silent><expr> <PageUp> coc#pum#visible() ? coc#pum#scroll(0) : "\<PageUp>"
" ctrl b/f too:
inoremap <silent><expr> <C-b> coc#pum#visible() ? coc#pum#scroll(1) : "\<C-b>"
inoremap <silent><expr> <C-f> coc#pum#visible() ? coc#pum#scroll(0) : "\<C-f>"
"  TODO enabling both imap and nmap below is causing something else to break and only one is gonna work at a time with this config, todo figure out what is actually going on and stop hacking at these mappings as if they live alone
"
" coc#float is for hover docs
" #has_scroll() and has_float() are available to check if it is visible/scrollable
" FYI    :echo coc#float#has_scroll() " returns 1 if visible, 0 if not
" TODO disabled for float hover help for now, as I should use that less, can bring it back when I do real troubleshooting
"nnoremap <silent><expr> <PageDown> coc#float#has_scroll() ? coc#float#scroll(1) : "\<PageDown>"
"nnoremap <silent><expr> <PageUp> coc#float#has_scroll() ? coc#float#scroll(0) : "\<PageUp>"
"" issue with neoscroll which maps Page up/down to ctrlb/f so I need those here too
"" ABSOLUTELY A LOADING ISSUE... if this loads before neoscroll then this wins out, else neoscroll wins out
""  and yet neoscroll winnning doesn't seem to always be an issue either.. WTF.. .is it the session?
"nnoremap <silent><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-b>"
"nnoremap <silent><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-f>"



" Use <c-space> to trigger/refresh completion
inoremap <silent><expr> <c-space> coc#refresh()

" * prev/next navigation using ][
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> [e <Plug>(coc-diagnostic-prev-error)
nmap <silent> ]e <Plug>(coc-diagnostic-next-error)
nmap <silent> [r CocNext
nmap <silent> ]r CocPrev



" * GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
"nmap <silent> gd <Cmd>Telescope coc definitions<CR>
"
nmap <silent> gy <Plug>(coc-type-definition)
"nmap <silent> gy <Cmd>Telescope coc type_definitions<CR>
"
nmap <silent> <leader>gi <Plug>(coc-implementation)
"nmap <silent> <leader>gi <Cmd>Telescope coc implementations<CR>
"
" FYI I am going back to coc's references picker, unfortunately
"  when I use telescope's ... it doesn't support :CocResume/:CocNext/:CocPrev (see keymaps below)
"  so I have to redo search each time! ouch
"  applies to all coc pickers
"  TODO investigate if I can get resume w/ telescope's picker which I prefer in some ways
nmap <silent> <leader>gr <Plug>(coc-references)
"nmap <silent> <leader>gr <Cmd>Telescope coc references<CR>
" TODO shift-F12 not working, is that chord already mapped and/or not coming across as such?
nmap <silent> <S-F12> <Plug>(coc-references)
"nmap <silent> <S-F12> <Cmd>Telescope coc references<CR>
"
nmap <silent> <F12> <Plug>(coc-definition)
"nmap <silent> <F12> <Cmd>Telescope coc definitions<CR>

nnoremap <silent> <S-k> :call ShowDocumentation()<CR>
function! ShowDocumentation()
    if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
    else
        call feedkeys('K', 'in')
    endif
endfunction


" TODO! review more of the CocActions and API here:
" TODO! https://github.com/neoclide/coc.nvim/blob/master/doc/coc.txt

" disabled for now, multiline strings in lua aren't recognized as nested code which makes sense...
" so any time cursor stops in the multiline string it higlights all of it (yuck)
" TODO change style of highlight
" TODO can I disable highlighting if there are no other matches?
" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming (I love F2 for this, maybe get rid of rn if I use F2 alone)
nmap <leader>rn <Plug>(coc-rename)
nmap <F2> <Plug>(coc-rename)

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

" * Map function and class text objects
" TODO habituate if/of
" in visual and operator pending modes
" if = inner function
" of = outer function
" same idea w/ classes
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
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

" Use CTRL-S for selections ranges
" Requires 'textDocument/selectionRange' support of language server
"   luals doesn't have this
" default suggests <C-s> which I want for saving...
" use <C-S-s> (shift+s) to use this...
"   incrementally expands selection outward (higher scopes)
"   coc-range-select-backward is inward (reduces selection to nested scopes)
nmap <silent> <C-S-s> <Plug>(coc-range-select)
xmap <silent> <C-S-s> <Plug>(coc-range-select)
"   PRN map coc-range-select-backward ?

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

" * CoCList related keymaps
" TODO habituate
"   this is like loclist and quickfix, but specific to CoC
"   i.e. if you find refs => go to first one => wanna go next in list:
"     :CocNext/:CocPrev
" FYI using <leader>c as prefix for now, that way these are "namespaced"
"   means WhichKey will help me recall them
" CocList has fuzzy matchers, so a nice way to grok the relevant info (i.e. diagnostics or outline)
"
nnoremap <silent><nowait> <space>ca  :<C-u>CocList diagnostics<cr>
" Find symbol of current document (outline)
" wow this is a nice way to jump to where I want for symobls in current file
nnoremap <silent><nowait> <space>co  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent><nowait> <space>cs  :<C-u>CocList -I symbols<cr>
nnoremap <silent><nowait> <space>cf  :<C-u>CocFirst<CR>
nnoremap <silent><nowait> <space>cl  :<C-u>CocLast<CR>
nnoremap <silent><nowait> <space>cn  :<C-u>CocNext<CR>
nnoremap <silent><nowait> <space>cp  :<C-u>CocPrev<CR>
nnoremap <silent><nowait> <space>cr  :<C-u>CocListResume<CR>
"
" not that important to me, can remove:
nnoremap <silent><nowait> <space>ce  :<C-u>CocList extensions<cr>
nnoremap <silent><nowait> <space>cc  :<C-u>CocList commands<cr>




" check for watchman and warn (prominently) that its missing
"   makes a big impact in terms of performance (otherwise fallbacks to polling)
"   esp on large projects, so make sure its present!
if executable('watchman') == 0
  echohl ErrorMsg
  echom 'Warning: watchman not found. coc.nvim may be slower without it.'
  echom '  USE brew install watchman'
  echohl None
endif

