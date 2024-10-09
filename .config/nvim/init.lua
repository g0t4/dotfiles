
local packer = require 'packer'
packer.startup(function()
	-- on changes, resource this file and :PackerSync
	-- :PackerCompile
	-- :PackerClean   (remove unused)
	-- :PackerInstall (install new)
	-- :PackerUpdate
	-- :PackerSync (update+compile)
	--     nvim observation: install window opens and can use `q` to close without :q 
   	
	-- packer manages packer, is that wise? 
	-- w/o this packer asks to remove packer, so I added this, run :PackerCompile, then :PackerSync and it doesn't ask to remove packer now
	use 'wbthomason/packer.nvim' 

	use 'Mofiqul/vscode.nvim'

	use 'github/copilot.vim'
end)

vim.cmd('colorscheme vscode') -- beautiful!



--" Uncomment the following to have Vim jump to the last position when reopening a file
vim.cmd([[
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
]])
-- TODO how does neovim not have this by default?


-- wrap settings
vim.o.wrap = false -- global nowrap, consider local settings for this instead
vim.o.textwidth = 0 -- disable globally, add back if I find myself missing it

-- *** tabs
-- I chose option 2 (always insert spaces, leave tabs as is with default tabstop=8)
vim.o.expandtab = true -- insert spaces for tabs
vim.o.softtabstop = 4 -- b/c expandtab is set, this is the width of an inserted tab in spaces
vim.o.shiftwidth = 4 -- shifting: << >>
-- vim.o.tabstop -- leave as is (8) so existing uses of tabs match width likely intended 

-- *** show whitespace
vim.opt.listchars = {tab='→ ',trail='·',space='⋅'} -- FYI also `eol:$`
vim.cmd("command! ToggleShowWhitespace if &list | set nolist | else | set list | endif")

-- TODO: port from vimrc
-- " *** review `autoindent`/`smartindent`/`cindent` and `smarttab` settings, I think I am fine as is but I should check
--     filetype plugin indent on " this is controlling indent on new lines for now and seems fine so leave it as is 
--     set backspace=indent,start,eol " allow backspacing over everything in insert mode, including indent from autoindent, eol thru start of insert

--[[ 
NOTES (vimscript => lua)

vim.cmd({cmd}) to execute a vimscript command

vim.o (== :set) 
	https://neovim.io/doc/user/lua.html#vim.o
vim.opt for list/map options (access as lua tables, i.e. append/prepend/remove elements)
	https://neovim.io/doc/user/lua.html#vim.opt
]]--

