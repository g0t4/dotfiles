-- *** treesitter helpers, i.e. for understanding highlighting issues

function print_captures_at_cursor()
    local myTable = vim.treesitter.get_captures_at_cursor()
    for key, value in pairs(myTable) do
        print(key, value)
    end
end

vim.cmd("nnoremap <leader>pc :lua print_captures_at_cursor()<CR>")

-- TODO! treesitter-highlight-priority ... sets nvim_buf_set_extmark() to 100.. so how does that relate to my syntax/highlight groups? how do I see that?
vim.cmd [[

    " FYI if I can also remove @comments capture linkage https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/lua/highlights.scm#L229-L230
    " TODO add custom capture that targets subset of comments insted of using regex, so I can target both syntax and/or treesitter highlight systems

    " TODO try using extmarks instead of regex to highlight comments, many plugins use that for color and it seems to take precedence easily over treesitter too?

    " FYI nested comments here are also tagged as lua strings... and thus the fg green color overrides...
    "    so, what is happening is treesitter links to highlight groups and I cleared the one for Comment and fixed that conflict w/ my custom comment styles
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

function print_ts_cursor_details()
    -- FYI use :Inspect to see more info about highlights
    --
    local ts = vim.treesitter
    local ts_utils = require 'nvim-treesitter.ts_utils'

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
    print("name gui:'", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "name", "gui"),
        "' - cterm:", vim.fn.synIDattr(vim.fn.synID(cursor_row, cursor_col, 0), "name", "cterm"))

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
vim.cmd("nnoremap <leader>pi :Inspect<CR>") -- prefer over pd/pc I made, b/c this shows treesitter/syntax/extmarks differences
--
-- vim.api.nvim_create_autocmd("BufReadPost", {
--     callback = function()
--         vim.cmd("source ~/.config/nvim/lua/plugins/vimz/highlights.vim")
--     end
-- })


-- disable with flip true/false, for perf testing
if true then

    -- Step 1: Define the highlight group for TODOs
    vim.api.nvim_set_hl(0, 'CommentTODO', { fg = "#ffcc00" })
    vim.api.nvim_set_hl(0, 'CommentTODOBang', { bg = "#ffcc00", fg = "#1f1f1f", bold = true })
    vim.api.nvim_set_hl(0, 'CommentPRN', { fg = "#27AE60" })
    vim.api.nvim_set_hl(0, 'CommentPRNBang', { bg = "#27AE60", fg = "#1f1f1f", bold = true })
    vim.api.nvim_set_hl(0, 'CommentAsterisk', { fg = "#ff00c3" })
    vim.api.nvim_set_hl(0, 'CommentAsteriskBang', { bg = "#ff52d1", fg = "#1f1f1f", bold = true })

    -- Step 2: Function to highlight TODO comments
    local function highlight_todo()
        local ns_id = vim.api.nvim_create_namespace("highlighting_comments")

        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)


        local function find_comment(line)
            local start_col, end_col = line:find("[#/%-]*%sTODO!.*")
            if start_col then
                return start_col, end_col, "CommentTODOBang"
            end

            start_col, end_col = line:find("[#/%-]*%sTODO.*")
            if start_col then
                return start_col, end_col, "CommentTODO"
            end

            start_col, end_col = line:find("[#/%-]*%sPRN!.*")
            if not start_col then
                start_col, end_col = line:find("[#/%-]*%sFYI!.*")
            end
            if start_col then
                return start_col, end_col, "CommentPRNBang"
            end

            start_col, end_col = line:find("[#/%-]*%sPRN.*")
            if not start_col then
                start_col, end_col = line:find("[#/%-]*%sFYI.*")
            end
            if start_col then
                return start_col, end_col, "CommentPRN"
            end


            -- ***! asterisk
            start_col, end_col = line:find("[#/%-]*%s*%*!.*")
            if start_col then
                return start_col, end_col, "CommentAsteriskBang"
            end
            -- * single or more asterisk
            start_col, end_col = line:find("[#/%-]*%s*%*.*")
            if start_col then
                return start_col, end_col, "CommentAsterisk"
            end





            --


        end

        for i, line in ipairs(lines) do
            local start_col, end_col, hl_group = find_comment(line)
            if start_col then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, start_col - 1, {
                    end_col = end_col,
                    hl_group = hl_group
                })
            end
        end
    end

    -- Step 3: Autocommand to refresh on TextChanged
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
        callback = highlight_todo,
    })

end





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
