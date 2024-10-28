-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    print(vim.inspect(vim.treesitter.get_captures_at_cursor()))
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")

-- TODO! treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. so how does that relate to my syntax/highlight groups? how do I see that?
vim.cmd [[

    " FYI if I can also remove @comments capture linkage https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/lua/highlights.scm#L229-L230
    " TODO add custom capture that targets subset of comments insted of using regex, so I can target both syntax and/or treesitter highlight systems

    " TODO try using extmarks instead of regex to highlight comments, many plugins use that for color and it seems to take precedence easily over treesitter too?

    " FYI nested comments here are also tagged as lua strings... and thus the fg green color overrides...
    "    so, what is happening is treesitter links to highlight groups and I cleared the one for Comment and fixed that conflict w/ my custom comment styles
    "    AND first doc loaded still doesn't get my highlights... just FYI thats the other bug that can be confusing
    " * override Comment color => changes the fg!
    hi clear Comment " clear it fixes the fg color ... b/c then yeah a comment doesn't have a fg color... ok... but can I add back color as a lower precedence rule?
    "hi Comment ctermfg=65 guifg='#6a9955'   "original => Last set from ~/.local/share/nvim/site/pack/packer/start/vim-code-dark/colors/codedark.vim
    "hi Comment guibg='#6a9955'   "original => Last set from ~/.local/share/nvim/site/pack/packer/start/vim-code-dark/colors/codedark.vim
    "hi Comment ctermfg=65 guibg='#6a9955' guifg='#0101ff' "!!! bgcolor takes precedence too, so its a precedence issue IIGC
    " hi Comment ctermfg=65 guifg='#0101ff' gui=NONE " NONE doesn't take precedence, is that even valid though?
    " OMG OMG  if I break this style with invalid guifg!! my styles work in lua!!!! **tears** (all damn day beating around this bush)


    " explore capture => highlighting
    " captures are linked to existing highlight groups (IIUC for the most part), i.e.:
    ":hi TestNewHigh gui=bold guibg=red guifg=blue " create new highlight rule
    ":hi link @comment TestNewHigh  " link capture to it
    " FYI here is logic to add higlighting to a node: (is this used by extensions?)  https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua#L268

]]

-- FYI! foo
-- !!! FOO
-- alternative way to replace higlight group:
-- -- vim.api.nvim_set_hl(0, "Comment", {})
-- -- vim.api.nvim_set_hl(0, "Comment", { fg = "#6a9955" })
-- vim.api.nvim_set_hl(0, "@comment", {})

vim.cmd("nnoremap <leader>pi :Inspect<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences

-- TODO remove once I am happy with new treesitter based highlights that aren't conflicting at all given treesitter highlights take precedence (IIUC) over "legacy" syntax highlights
-- vim.api.nvim_create_autocmd("BufReadPost", {
--     callback = function()
--         vim.cmd("source ~/.config/nvim/lua/plugins/vimz/highlights.vim")
--     end
-- })

-- TODO
-- load wilder.vim:
-- vim.cmd('source /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/nvim/todo_vimrc.vim')

-- HIGHLIGHT 3 (maybe) => ultimately I need to understand what all is fighting over highlights/syntax/etc (treesitter, vim regex syntax, LSP too?, syntect (sublime text)..)
--     autocmd filetype    -- super helpful way to see what is applied in what order (where I found the autocmds were registered too early... so maybe put back earlier registration and see if I can find the things in between that are overriding higlights)
--         IN FACT => do binary search on registration order in the plugin chain... see if I can narrow the extension causing issues, IIAC
-- " !!! try AFTER plugin config:
--
-- use {
--   'plugin-to-load-second',
--   after = 'plugin-to-load-first',
--   config = function()
--     -- Your Vimscript or Lua code that depends on `plugin-to-load-first`
--     vim.cmd('echo "Plugin loaded after plugin-to-load-first"')
--   end
-- }
-- OBSERVATIONS:
--   both bg and gui=bold are applied correctly to lua files... just the fg color?!
--   nvim -u NONE ~/.config/nvim/init.lua
--     run w/ no plugins => then
--       :source  ~/.config/nvim/immediate.highlights.vim
--            WORKS! applies my style to FYI below

--
-- HIGHLIGHT ISSUE 2 => lua seems to have smth else styling it and that is overrding fg colors... I dont think its treesitter b/c I configured it to disable it and this still persisted..
--
--
-- HIGHLIGHT ISSUE 1 => most files the style didn't apply (until I discovered you reload the file and that registers the autocmd FileType entries again and that must be overrdiing whatever is blocking the first registration which was before many plugin highlights...)
-- ensure highlight style applied late in load process (before buffer ready but just after file read)...  b/c right now if these are registered earlier (ie before packer plugins...) then the style wont take effect until next file opened
--
--
