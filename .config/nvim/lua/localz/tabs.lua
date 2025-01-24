-- definitely move this elsewhere later
-- wrap settings
vim.o.wrap = false -- global nowrap, consider local settings for this instead
vim.o.textwidth = 0 -- disable globally, add back if I find myself missing it
vim.o.wrapmargin = 0 -- disable globally, add back if I find myself missing it
-- TODO ftplugin/ is overriding textwidth for vim script... grrr

-- *** tabs
-- I chose option 2 (always insert spaces, leave tabs as is with default tabstop=8)
vim.o.expandtab = true -- insert spaces for tabs
vim.o.softtabstop = 4 -- b/c expandtab is set, this is the width of an inserted tab in spaces
vim.o.shiftwidth = 4 -- shifting: << >>
-- vim.o.tabstop -- leave as is (8) so existing uses of tabs match width likely intended

-- *** show whitespace
vim.opt.listchars = { tab = '→ ', trail = '·', space = '⋅' } -- FYI also `eol:$`
vim.cmd([[
    command! ToggleShowWhitespace if &list | set nolist | else | set list | endif
]])

-- *** command to show tab config (print messages)
vim.api.nvim_create_user_command('TroubleshootOptions', function()
  -- sometimes things are misconfigured and I wanna dump the config all at once that is likely affected (i.e. my werkspace plugin, the lua file loaded doesn't seem to apply the editorconfig values for lua but if I :e! then it does)
  -- expandtab == true => insert spaces for tabs (used w/ < > commands and when autoindent=on)
  --
  print(
  -- print first so it doesn't show unless :messages
    "wrap:" .. tostring(vim.o.wrap),
    "wrapmargin:" .. tostring(vim.o.wrapmargin),
    "textwidth:" .. tostring(vim.o.textwidth),
    "linebreak:" .. tostring(vim.o.linebreak),
    " - ",
    -- noteworthy:
    -- t = auto-wrap text using textwidth
    -- c = auto-wrap comments using textwidth
    "formatoptions:" .. tostring(vim.o.formatoptions)
  )
  -- ok to have super wide output... most of the time I have full screen width... and zoomed small
  print("expandtab:" .. tostring(vim.o.expandtab),
    "softtabstop:" .. tostring(vim.o.softtabstop),
    "shiftwidth:" .. tostring(vim.o.shiftwidth),
    "tabstop:" .. tostring(vim.o.tabstop),
    " - ",
    "autoindent:" .. tostring(vim.o.autoindent),
    "smartindent:" .. tostring(vim.o.smartindent),
    "cindent:" .. tostring(vim.o.cindent),
    "smarttab:" .. tostring(vim.o.smarttab)
  )
end, { bang = true })

-- *** review `autoindent`/`smartindent`/`cindent` and `smarttab` settings, I think I am fine as is but I


-- TODO: port from vimrc
-- " *** review `autoindent`/`smartindent`/`cindent` and `smarttab` settings, I think I am fine as is but I should check
--     filetype plugin indent on " this is controlling indent on new lines for now and seems fine so leave it as is
--     set backspace=indent,start,eol " allow backspacing over everything in insert mode, including indent from autoindent, eol thru start of insert
