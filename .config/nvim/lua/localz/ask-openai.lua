
-- *** ASK OPENAI wrapper
vim.cmd([[
    " nvim observation: nested languages in lua are highlighted nicely!
    "   lua observation: multiline strings rock for embedding other languages

    " TODO review prompt and see if I should specify this is neovim vs classic... in fact I should update this wrapper to differentiate and pass that

    function! TrimNullCharacters(input)
        " Replace null characters (\x00) with an empty string
        " was getting ^@ at end of command output w/ system call (below)
        return substitute(a:input, '\%x00', '', 'g')
    endfunction

    function! AskOpenAI()

        let l:cmdline = getcmdline()

        " todo this prompt here should be moved into vim.py script and combined with other system message instructs? specifically the don't include leading :? or should I allow leading: b/c it still works to have it
        let l:STDIN_text = ' env: nvim (neovim) command mode (return a valid command w/o the leading : ) \n question: ' . l:cmdline

        " PRN use env var for DOTFILES_DIR, fish shell has WES_DOTFILES variable that can be used too
        let l:DOTFILES_DIR = '~/repos/wes-config/wes-bootstrap/subs/dotfiles'
        let l:py = l:DOTFILES_DIR . '/.venv/bin/python3'
        let l:vim_py = l:DOTFILES_DIR . '/zsh/universals/3-last/ask-openai/vim.py'
        let l:command_ask = l:py . ' ' . l:vim_py

        let l:result = system(l:command_ask, l:STDIN_text)

        return TrimNullCharacters(l:result)

    endfunction

    " Map a key combination to the custom command in command-line mode
    cmap <C-b> <C-\>eAskOpenAI()<CR>

]])


