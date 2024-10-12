
vim.cmd [[

    command! CopyGitHubLink call CopyGitHubLink()

    function! BuildGitHubLink()
      " Get current file path relative to the git root
      let l:filepath = system('git rev-parse --show-prefix') . expand('%')

      " Get current branch
      let l:branch = system('git rev-parse --abbrev-ref HEAD')

      " Get GitHub remote URL and clean it up
      let l:remote_url = system('git config --get remote.origin.url')
      let l:remote_url = substitute(l:remote_url, 'git@github.com:', 'https://github.com/', '')
      let l:remote_url = substitute(l:remote_url, '.git\n$', '', '')

      " Get current line number
      let l:line_number = line('.')

      " Build the full GitHub link
      let l:github_url = l:remote_url . '/blob/' . l:branch . '/' . l:filepath . '#L' . l:line_number

      " trim new lines
      let l:github_url = substitute(l:github_url, '\n', '', 'g')
      return l:github_url
    endfunction

    function! CopyGitHubLink()
        let l:github_url = BuildGitHubLink()
        let @+ = l:github_url
        echo 'GitHub link copied: ' . l:github_url
    endfunction

    command! OpenGitHubLink call OpenGitHubLink()

    function! OpenGitHubLink()
        let l:github_url = BuildGitHubLink()
        " # has to be escaped, smth with vim dispatch (no alternate file name to substitute for '#')
        let l:escaped_url = substitute(l:github_url, '#', '\\#', 'g')
        execute 'silent !open "' . l:escaped_url . '"'
    endfunction


]]


