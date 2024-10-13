---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
-- TODO would be nice to fix these missing globals (and have them resolve to real deal, or worse case explicitly ignore one by one (not all or none))


-- FYI these are mission critical things to have during a failure

--" Uncomment the following to have Vim jump to the last position when reopening a file
vim.cmd([[
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
]])



vim.o.ignorecase = true -- ignore case when searching



