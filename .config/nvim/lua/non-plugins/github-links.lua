vim.cmd [[

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

    " FYI range argument (to function) is essential, otherwise a multi-line selection triggers once per line!
    "   :h :func-range
    "   range is passed as a:firstline and a:lastline
    "   and interestingly, a:firstline==a:lastline when there is no range selected, thanks gain to range arg to func command
    function! OpenGitHubLink(is_permalink) range
        " echo a:firstline ' , ' a:lastline
        let l:github_url = BuildGitHubLink(a:firstline, a:lastline, a:is_permalink)
        " # has to be escaped, smth with vim dispatch (no alternate file name to substitute for '#')
        let l:escaped_url = substitute(l:github_url, '#', '\\#', 'g')
        execute 'silent !open "' . l:escaped_url . '"'
        " TODO I almost wanna keep the seletion after copying/opening the link? right now on invocation of a func then selection is moved to the first line
        "   my thought is, what if I grab the wrong range? that said I can just edit the line #s too
        "   so for now leave this with normal behavior
    endfunction

    " FYI -range / <line1>,<line2> makes it possible to:
    "   select lines, type ":" to go into command mode and directly type just command name (instead of call CopyGitHubLink(v:false))
    "     :'<,'>CopyGitHubLink
    "     :'<,'>OpenGitHubLink
    "   and, these still work too with a single line:
    "     :CopyGitHubLink
    "     :OpenGitHubLink
    "   FYI the commands have nothing to do with keymaps below, these commands are just helpers to quickly invoke the func via commandline
    "     with the keymaps, I really don't need the commands, I just used those in the past so I will have a tendency to use them again
    "     also I may get rid of the keymaps if those cause trouble
    command! -range CopyGitHubLink <line1>,<line2>call CopyGitHubLink(v:false)
    command! -range CopyGitHubPermaLink <line1>,<line2>call CopyGitHubLink(v:true)
    command! -range OpenGitHubLink <line1>,<line2>call OpenGitHubLink(v:false)
    command! -range OpenGitHubPermaLink <line1>,<line2>call OpenGitHubLink(v:true)

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
