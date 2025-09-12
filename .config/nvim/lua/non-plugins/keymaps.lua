local default_options = { noremap = true, silent = true }

-- *** s and S => / and ?
--   inspired by trying vim-sneak which I like that s/S is much easier to type!
--   and I don't much find myself using s/S key for substitute command in normal/vim modes
--   as for S... I really like cc anyways... so I won't likely need S ever...
--   as for s... cl is not at all intuitive... (it could be if I work on it)... so this is a loss but honestly I rarely used s thus far... so lets see how I feel
--   downside to remapping is getting in wrong habit :)... for vim envs w/o my config :)
-- vim.keymap.set({ "n", "v" }, "s", "/", default_options)
-- TODO find new kemap, captial S conflicts with nvim-surround
-- vim.keymap.set({ "n", "v" }, "S", "?", default_options)


-- *** window keymaps
for _, arrow in ipairs({ "right", "left", "up", "down" }) do
    -- simpler:
    -- vim.keymap.set({ "n" }, "<M-" .. arrow .. ">", "<C-W><" .. arrow .. ">", default_options)
    -- vim.keymap.set({ "i" }, "<M-" .. arrow .. ">", "<Esc><C-W><" .. arrow .. ">", default_options)
    --
    -- <Cmd>wincmd == one keymap for both modes (n/i) + preserve mode after switch
    --   also, this adds 4 fewer keymaps overall, so when I use :map to list them all, I see fewer
    local dir = arrow == "left" and "h" or arrow == "right" and "l" or arrow == "up" and "k" or "j"
    -- disable "i" insert mode b/c I use alt+right for accept next work in suggestions
    vim.keymap.set({ "n" }, "<M-" .. arrow .. ">", "<Cmd>wincmd " .. dir .. "<CR>", default_options)
end
-- FYI can use Shift+Alt+arrows to move some other thing, might even want that for window moves if not something else b/c that is what I use in iterm2 for switching panes in a split tab/window

-- *** tab keymaps
vim.keymap.set({ "n", "i", "v" }, "<C-t>", "<Cmd>tabnew<CR>", default_options)
-- FYI F8 maps to close window (repeat to close all windows in a tab is fine in most cases)
--
-- switch tabs (use defaults, they all seem reasonable):
--   <C-PageUp/Down> *** switches tabs, default!
--   gt/gT # * goto next/prev
--     2gt # * goto tab # (i.e. 2)
--     g<Tab> # ** last tab
--   :tabp[revious] :tabN[ext] :tabfir[st] :tabl[ast]
--   :tabm[ove] [+/-]N   # move to after tab N, or -N/+N relative move

-- *** Ctrl+S to save http://vim.wikia.com/wiki/Saving_a_file
-- <cmd> preserves mode and is independent of initial mode
-- <cmd> also preserves visual mode selection!
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", default_options)
-- vim.cmd("nnoremap <c-s> :w<CR>")
-- vim.cmd("vnoremap <c-s> <Esc><c-s>gv") -- esc=>normal mode => save => reselect visual mode, not working... figure out later
-- vim.cmd("inoremap <c-s> <c-o><c-s>")

-- F9 == quit all
vim.keymap.set({ "v", "n", "i" }, "<F9>", "<cmd>qall<CR>", default_options)
vim.keymap.set({ "v", "n", "i" }, "<F8>", "<cmd>q<CR>", default_options)
-- perhaps I am doing something wrong if I need F9.. but I love this, open lots of tabs to test neovim config changes and just wanna close w/o BS... also love one click quit if no changes
-- FYI F10 is F9 + re-run nvim (in keyboard maestro to relaunch nvim after quitting)


-- map [Shift]+Ctrl+Tab to move forward/backward through files to edit, in addition to Ctrl+o/i
--   that is my goto key combo, perhaps I should learn o/i instead... feel like many apps use -/+ for this, vscode for shizzle
vim.keymap.set('n', '<C-->', '<C-o>', default_options)
vim.keymap.set('n', '<C-S-->', '<C-i>', default_options)
--  FYI in iTerm => Profiles -> Keys -> Key Mappings -> removed "send 0x1f" on "ctrl+-" ... if that breaks something, well you have this note :)



-- *** help
--
-- start typing :help then Ctrl+R, Ctrl+W takes word under cursor
vim.keymap.set('n', '<F1>', ':help <C-R><C-W><CR>', { noremap = true, silent = true })
--
-- take current big word and open a help page for it on web page based on what is shown
--   I want hs.canvas => https://www.hammerspoon.org/docs/hs.canvas.html#canvasDefaultFor
--   so if starts with "hs." then I can build link and open it (like gx)
function OpenWebHelp()
    local bigWord = vim.fn.expand("<cWORD>")
    if bigWord:sub(1, 3) == "hs." then
        return OpenWebHelpHammerspoon(bigWord)
    end
    -- TODO how about ask qwen2.5 model locally to suggest the link and open it?
    --    IOTW have hard mappings above (esp for thinks qwen fails at and then otherwise use qwen)
    print("ADD MORE HELP MAPPINGS to OpenWebHelp")
end

function OpenWebHelpHammerspoon(bigWord)
    -- examples:
    --   hs.application.get("foo") => https://www.hammerspoon.org/docs/hs.application.html#get
    --   hs.axuielement.observer.new  -- 3 dots => https://www.hammerspoon.org/docs/hs.axuielement.observer.html#new
    --   hs.application.get  -- 2 dots => https://www.hammerspoon.org/docs/hs.application.html#get
    --   hs.application   -- 1 dot => https://www.hammerspoon.org/docs/hs.application.html

    if bigWord:find("%(") then
        -- string trailing function call, take everything up until first open parens
        bigWord = bigWord:match("^(.*)%(")
    end

    local dotCount = select(2, bigWord:gsub("%.", ""))
    if dotCount < 2 then
        -- if only one dot => treat as module
        vim.cmd("!open 'https://www.hammerspoon.org/docs/" .. bigWord .. ".html'")
        return
    end

    local docsPath = bigWord:gsub("^(.*)%.([^%.]*)$", "%1.html%\\#%2")
    --    FYI # must be escaped or will be replaced with current file path (part of vim cmdline)
    vim.cmd("!open 'https://www.hammerspoon.org/docs/" .. docsPath .. "'")
end

vim.keymap.set('n', '<S-F1>', OpenWebHelp, { noremap = true, silent = true })
--
vim.keymap.set('x', '<F1>', 'y:help <C-R>"<CR>', { noremap = true, silent = true })
vim.keymap.set('v', '<F1>', function()
    -- *** in visual mode, press F1 to search for selected text, or select word under cursor
    -- local mode = vim.fn.visualmode()

    -- current visual seletion start/end:
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    -- FYI '<, '> are positions of LAST visual selection (not current)
    -- this is why '<,'> is inserted into command line when you select text! now it makes sense! ' == mark, </> are the mark "register" names
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    -- vim.cmd('normal! gv') -- reselect LAST visual selection ('<,'> marks)

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- print("start/end", vim.inspect(start_pos), "/", vim.inspect(end_pos))
    if start_line == end_line and start_col == end_col then
        -- print("  only one char, expanding selection to word")
        vim.cmd('normal! iw') -- selects word under cursor (since one char alone isn't really a selection and if it is then this won't change it!)
        -- think of this as not requiring user to make simple selections, do it for them
    end

    -- yank selection into " register
    vim.cmd('normal! ""y')

    local search_term = vim.fn.getreg("\"")
    -- print("  search term: '", search_term, "' (w/o single quotes)")
    vim.cmd('help ' .. search_term)
end)

vim.keymap.set('c', '<F1>', function()
    -- *** help for cmdline contents
    local cmdline = vim.fn.getcmdline()

    -- use Ctrl+C to cancel cmdline mode (otherwise help won't show until after you exit cmdline mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), 'n', false)

    -- TODO if mutliple words, take first word that has help? OR word under cursor?
    vim.cmd('help ' .. cmdline, { silent = true })

    -- could attempt to put cmdline back so it can be edited again BUT people wanted help so stay in help, they can always uparrow to get back cmd next time they enter cmdline mode
    -- pointless to put back the cmdline unless someone was just gonna read the start of the help which is doubtfully enough
    -- vim.api.nvim_feedkeys(":", 'n', false)
end)

-- NO idea why these won't work in lua vim.keymap.set but they don't :(
vim.cmd [[
    " map ctrl+/ (similar to cmd+/ in vscode/zed), IIAC windows uses ctrl+/ in vscode?
    " NOTE, I want 6<C-/> to do 6gcc
    nmap <C-/> gcc
    " gcc is 3 keystrokes, for a very common command
    " <C-/> is 1 chord (eqiv to 1 keystroke), not 3 key/chors in a row
    " only issue C-/ won't work with trailing motions, i.e. gc{
    vmap <C-/> gcc
]]


-- --- * paste as an operator!
-- --- * -["x]p{motion}
-- -- PRN... showstopper ... what to do with traditional paste?
-- --      lose the ability to just 'p'
-- --   AFAICT there isn't a timeout for operatorfunc?
-- --   or if it times out it does nothing?
-- --
-- -- inspired by other operations:
-- -- -["x]c{motion}
-- -- -["x]d{motion}
-- -- -["x]y{motion}
-- -- -["x]zy{motion}
-- --
-- -- :h g@
-- -- :h text-objects
-- --
-- -- try it:
-- -- - yank words in visual charwise => pastes in charwise
-- --    yiw (yank inner word) => piW (paste around word)
-- --    copy smth => pip (paste inner paragraph)
-- --
-- -- think p == v{motion}p
-- --
--
-- vim.keymap.set("n", "p", function()
--     vim.o.operatorfunc = "v:lua.paste_as_operator"
--     return "g@"
-- end, { expr = true })
--
-- vim.keymap.set("x", "p", function()
--     vim.o.operatorfunc = "v:lua.paste_as_operator"
--     return "g@"
-- end, { expr = true })
--
-- function paste_as_operator(type)
--     print("type: ", type)
--     local register = vim.fn.getreg('*')
--     commands = {
--         char = "normal `[v`]",
--         line = "normal `[V`]",
--         block = "normal `[\\<C-V>`]",
--     }
--     local which = commands[type]
--     -- print(which)
--     vim.cmd(which)
--     -- vim.cmd("normal `[")
--     -- -- TODO get line/char/block wise type (see `:h g@` for example )
--     -- vim.cmd("normal V")
--     -- vim.cmd("normal `]")
--     register = register or ""
--     vim.cmd("normal c") -- follows convention for yanking deleted text (or not)
--     vim.api.nvim_paste(register, false, -1)
--
--     -- if register ~= nil and register ~= '' then
--     --     -- TODO select
--     --     vim.cmd("normal d") -- follows convention for yanking deleted text (or not)
--     --     vim.api.nvim_paste(register, false, -1)
--     -- else
--     --     print("No text in primary register")
--     -- end
-- end

-- * gcl operator
-- [<count>]gcl<motion>
--
-- define gcl (l == linewise) operator (waits for a motion to select lines to apply to)
--  motion can be non-linewise but line only really makes sense for this operation
vim.keymap.set("x", "gcl", function()
    vim.o.operatorfunc = "v:lua.toggle_linewise_comments_operator_func"
    return "g@"
end, { expr = true })

vim.keymap.set("n", "gcl", function()
    vim.o.operatorfunc = "v:lua.toggle_linewise_comments_operator_func"
    return "g@"
end, { expr = true })

function toggle_linewise_comments_operator_func()
    local _comment = require('vim._comment')

    -- [bufnum, lnum, col, off]
    local start = vim.fn.getpos("'[")
    local finish = vim.fn.getpos("']")
    -- vim.print(start, finish)
    local start_line = start[2]
    local finish_line = finish[2]
    for line = start_line, finish_line do
        _comment.toggle_lines(line, line)
    end

    -- FYI there is a 3rd arg for cursor position, not using it so far
end
