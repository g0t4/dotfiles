-- ensure don't override base ftplugin for zsh:
vim.cmd('runtime! ftplugin/zsh.lua')

-- print("hi from zsh")
--

-- for now, use bash file type for zsh given treesitter lacks zsh support
vim.bo.filetype = "bash"
-- alternatively, disable treesitter for zsh
-- TSDisable highlight zsh
-- then vim's syntax highlighting will kick in (not much better)

-- PRN get zsh nested in markdown code blocks highlighted? I don't care much about zsh, but it is a good thing to learn to do, maybe with a diff lang?
-- zsh might not be recognized as markdown code block type?
