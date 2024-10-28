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
