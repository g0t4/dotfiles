local Log = require('legendary.log')

return function()
    local has_lazy, _ = pcall(require, 'lazy')
    if not has_lazy then
        Log.warn("lazy.nvim integration is enabled, but cannot `require('lazy')`, aborting.")
        return
    end

    local LazyNvimConfig = require('lazy.core.config')
    for _, plugin in pairs(LazyNvimConfig.plugins) do
        local keys = vim.tbl_get(plugin or {}, '_', 'handlers', 'keys') or {}
        for _, keymap in pairs(keys) do
            -- we don't need the implementation, since
            -- lazy.nvim will have already bound it. We
            -- just need the description-only item to appear
            -- in the legendary.nvim finder.
            -- WES note: IIAC the others bind keymaps too? so people use this as a tool to bind and find! ok makes sense

            -- FYI use this to see full lazy plugin config:
            --    :Dump require('lazy').plugins()

            -- FYI description MUST be set or its not shown
            local use_description = keymap.rhs
            if keymap.desc then
                use_description = use_description .. ' ' .. keymap.desc
            end

            local legendary_keymap = {
                -- for backwards compatibility, if keymap.lhs is missing, using an old lazy.nvim so it will be keymap[1]
                keymap.lhs or keymap[1],
                description = use_description,
                mode = keymap.mode, ---@type string|string[]|nil
            }
            require('legendary').keymap(legendary_keymap)
        end
    end
end
