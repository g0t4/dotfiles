-- Load any custom Vim/Neovim configuration that lives in a ".vim" directory
-- inside the workspace root.  This allows per‑project plugins, commands,
-- keymaps, etc. to be defined alongside the code they operate on.
local function load_workspace_vim()
    local root = require('non-plugins.werkspaces.api').get_werkspace_root_dir()
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
