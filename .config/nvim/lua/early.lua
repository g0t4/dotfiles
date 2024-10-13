
-- FYI these are mission critical things to have during a failure

--" Uncomment the following to have Vim jump to the last position when reopening a file
vim.cmd([[
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
]])
--
-- *** searching
vim.o.ignorecase = true -- ignore case when searching



