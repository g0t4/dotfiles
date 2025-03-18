
vim.cmd [[

    command! CopyGitHubLink call CopyGitHubLink(v:false)
    command! CopyGitHubPermaLink call CopyGitHubLink(v:true)

    function! BuildGitHubLink(start_line, end_line, is_permalink)

      " current file path relative to the repo root
      let l:file_path_in_repo = system('git rev-parse --show-prefix') . expand('%')

      if a:is_permalink
          let l:commit_ish = system('git rev-parse --short HEAD')
      else
          let l:commit_ish = system('git rev-parse --abbrev-ref HEAD')
      end

      let l:remote_url = system('git config --get remote.origin.url')
      let l:remote_url = substitute(l:remote_url, 'git@github.com:', 'https://github.com/', '')
      let l:remote_url = substitute(l:remote_url, '.git\n$', '', '')

      let l:github_url = l:remote_url . '/blob/' . l:commit_ish . '/' . l:file_path_in_repo . '#L' . a:start_line
      if a:start_line != a:end_line
         let l:github_url = l:github_url . '-L' . a:end_line
      endif

      " trim new lines
      let l:github_url = substitute(l:github_url, '\n', '', 'g')
      return l:github_url
    endfunction

    function! CopyGitHubLink(is_permalink) range
        let l:github_url = BuildGitHubLink(a:firstline, a:lastline, a:is_permalink)
        let @+ = l:github_url
        echo 'GitHub link copied: ' . l:github_url
    endfunction

    command! OpenGitHubLink call OpenGitHubLink(v:false)
    command! OpenGitHubPermaLink call OpenGitHubLink(v:true)

    " FYI range argument (to function) is essential, otherwise a multi-line selection triggers once per line!
    "   :h :func-range
    "   range is passed as a:firstline and a:lastline
    function! OpenGitHubLink(is_permalink) range
        let l:github_url = BuildGitHubLink(a:firstline, a:lastline, a:is_permalink)
        " # has to be escaped, smth with vim dispatch (no alternate file name to substitute for '#')
        let l:escaped_url = substitute(l:github_url, '#', '\\#', 'g')
        execute 'silent !open "' . l:escaped_url . '"'
    endfunction

    " PRN can use `gh` prefix if collisions w/ other needs
    "   right now I use `g` for references `gr` `gi`
    "   and it feels somewhat fitting to have `go` to go to (open) GitHub!
    "   then gl/gp can be for copying link/permalink, could do `gcp`/`gcl` too
    nnoremap <silent> <leader>go :call OpenGitHubLink(v:false)<CR>
    vnoremap <silent> <leader>go :call OpenGitHubLink(v:false)<CR>
    nnoremap <silent> <leader>gl :call CopyGitHubLink(v:false)<CR>
    vnoremap <silent> <leader>gl :call CopyGitHubLink(v:false)<CR>
    nnoremap <silent> <leader>gp :call CopyGitHubLink(v:true)<CR>
    vnoremap <silent> <leader>gp :call CopyGitHubLink(v:true)<CR>

]]


