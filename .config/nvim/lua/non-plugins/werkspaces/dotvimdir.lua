-- each werkspace can have a .vim dir nested in the root directory (i.e. repo root)
-- I will load and run whatever customizations from that directory so I can create commands and other specific customizations that only apply to that repo!
-- and I keep the code for it colocated with the code it is meant to serve!
-- i.e. I want to act on segments in my auto_edit repo... when I find a list of segments, and I have that in ipython in a terminal window b/c of iron.nvim
--    then I want to click one and have it play that segment! (for example)
--    so I'll

-- Find the root of the current workspace (the directory that contains a .git folder
-- or, if that fails, just use the directory of the currently opened file).
local function get_workspace_root()
    local cwd = vim.fn.getcwd()
    local root = vim.fn.finddir('.git', cwd .. ';')
    if root == '' then
        return cwd
    end
    return vim.fn.fnamemodify(root, ':h')
end
-- Load any custom Vim/Neovim configuration that lives in a ".vim" directory
-- inside the workspace root.  This allows per‑project plugins, commands,
-- keymaps, etc. to be defined alongside the code they operate on.
local function load_workspace_vim()
    local root = get_workspace_root()
    if not root or root == '' then return end
    local vim_dir = root .. '/.vim'
    local init_lua = vim_dir .. '/init.lua'
    -- If the ".vim" directory exists, add it to the runtime path so that
    -- `require` can find modules placed there.
    if vim.fn.isdirectory(vim_dir) == 1 then
        vim.opt.rtp:prepend(vim_dir)
    end
    -- If there is an "init.lua" inside the directory, source it.
    if vim.fn.filereadable(init_lua) == 1 then
        local ok, err = pcall(dofile, init_lua)
        if not ok then
            vim.notify(
                string.format('Error loading workspace config %s: %s', init_lua, err),
                vim.log.levels.ERROR
            )
        end
    end
end
-- Run the loader once Neovim has finished its startup sequence.
vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = load_workspace_vim,
})
