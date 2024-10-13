
-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    local myTable = vim.treesitter.get_captures_at_cursor()
    for key, value in pairs(myTable) do
        print(key, value)
    end
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")
local ts = vim.treesitter

local ts_utils = require 'nvim-treesitter.ts_utils'

-- TODO format vimscript (nested in lua)
-- ***! foo

-- TODO! test lua comment
-- TODO test too
-- TODO! treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. so how does that relate to my syntax/highlight groups? how do I see that?
vim.cmd [[

    " FYI if I can also remove @comments capture linkage https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/lua/highlights.scm#L229-L230
    " TODO add custom capture that targets subset of comments insted of using regex, so I can target both syntax and/or treesitter highlight systems

    " !!! TMP fix sets no bg color on comments ... which means here then in nested multiline vimscript lua's orange color applies which is fine ish
    " FYI! NBD that color is orange here... I can fix the overlapping priority later... heck even the lua issue isn't a deal breaker as all other files seem to not have issue (yet, maybe treesitter on them will cause issues)
    " * override Comment color => changes the fg!
    "hi Comment ctermfg=65 guifg='#6a9955'   "original => Last set from ~/.local/share/nvim/site/pack/packer/start/vim-code-dark/colors/codedark.vim
    " hi Comment ctermfg=65 guibg='#6a9955' guifg='#0101ff' "!!! bgcolor takes precedence too, so its a precedence issue IIGC
    " hi Comment ctermfg=65 guifg='#0101ff' gui=NONE " NONE doesn't take precedence, is that even valid though?
    hi clear Comment " clear it fixes the fg color ... b/c then yeah a comment doesn't have a fg color... ok... but can I add back color as a lower precedence rule?
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

function print_ts_cursor_details()
    -- FYI, use :InspectTree => :lua vim.treesitter.inspect_tree() => interactive select/inspect left/right split
    local node_at_cursor = ts_utils.get_node_at_cursor()
    if node_at_cursor then
        print("Node type: ", node_at_cursor:type())
        print("node text: ", vim.treesitter.get_node_text(node_at_cursor, 0)) -- shows the original source! FYI 0 = buffer with text, node lookup into that buffer IIUC
    else
        print("No node found")
    end

    -- API: https://neovim.io/doc/user/api.html
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

    -- FYI drop local to snoop on variables, i.e. parser:
    local parser = ts.get_parser(0)
    local lang_tree = parser:language_for_range({ cursor_row - 1, cursor_col, cursor_row - 1, cursor_col })
    if lang_tree then
        local lang_name = lang_tree:lang()
        print("language: ", lang_name)
    else
        print("language: unknown")
    end


    print("captures:")
    print_captures_at_cursor()

    -- TODO can I get highligther info from treesitter? too? think what I did below but for treesitter
    -- local id = parser:syntax_tree():get_property("highlighter"):query("highlighter", cursor_row, cursor_col)
    -- print(id)

    print("syntax highlighting (not treesitter highlighting):")
    print("name gui:'", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, false), "name", "gui"),
        "' - cterm:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, false), "name", "cterm"))

    print("highlight:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "highlight", ""))
    print("fg:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "fg", "gui"),
        "bg:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bg", "gui"))
    -- print("fg#:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "fg#", "gui"),
    --     "bg#:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bg#", "gui"))
    print("bold:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "bold", ""))
    print("italic:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "italic", ""))
    print("underline:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "underline", ""))
    print("undercurl:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "undercurl", ""))

    -- TODO!  test lua commment

    -- IIAC => if have multi syntax/highlight regex hits... then I can show them all here... but won't show any treesitter highlights
    local stack = vim.fn.synstack(cursor_row, cursor_col)
    -- print("length:", #stack)
    -- -- loop:
    for key, value in pairs(stack) do
        print("stack:", key, value, vim.fn.synIDattr(value, "name", "gui"))
    end
end

vim.cmd("nnoremap <leader>pd :lua print_ts_cursor_details()<CR>")

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        vim.cmd("source ~/.config/nvim/highlights.vim")
    end
})






-- vim.api.nvim_set_hl(0, "vimAutoCmd",{ fg = "red", bg = "red"})

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





