-- ensure don't override base ftplugin for zsh:
vim.cmd('runtime! ftplugin/zsh.vim')
-- FYI ensure the above is valid, otherwise seems to silently fail (and then things like syntax highlighting are mysteriously broken)
-- FYI search rtp:
--    :echo globpath(&rtp, 'syntax/zsh.vim', 1)
--    :echo globpath(&rtp, 'syntax/zsh.*', 1)


-- TODO do I want to just use bash file type for zsh?
--   EVEN THE SYNTAX HIGHLIGHTING is not great for zsh in zsh.vim (above)
-- vim.bo.filetype = "bash"
-- alternatively, disable treesitter for zsh
-- TSDisable highlight zsh
-- then vim's syntax highlighting will kick in (not much better)

-- PRN get zsh nested in markdown code blocks highlighted? I don't care much about zsh, but it is a good thing to learn to do, maybe with a diff lang?
-- zsh might not be recognized as markdown code block type?
