local M = {}


function M.setup()
    local cmp = require('cmp')

    -- note: I like that it doesn't show until first char typed (by default)

    local suggested_mapping = cmp.mapping.preset.cmdline()

    function get_half_screen_height_lines()
        return math.floor((vim.o.lines - vim.o.cmdheight) / 2)
    end

    -- now I build a new mapping based on selected mappings from preset that I want
    local mapping = {}
    mapping['<Tab>'] = suggested_mapping['<Tab>']
    mapping['<S-Tab>'] = suggested_mapping['<S-Tab>']
    -- * if this messes up command history, then fix this to conditionally move up/down (see below examples from preset mappings)
    mapping['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' })
    mapping['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' })
    -- move up/down by half screen height # of lines
    mapping['<C-D>'] = cmp.mapping(cmp.mapping.select_next_item({ count = get_half_screen_height_lines() }), { 'c' })
    mapping['<C-U>'] = cmp.mapping(cmp.mapping.select_prev_item({ count = get_half_screen_height_lines() }), { 'c' })
    -- vim.print(mapping)

    cmp.setup.cmdline({ '/', '?' }, {
        -- FYI appears that this can be different from mapping for cmdline below
        mapping = mapping,
        sources = {
            { name = 'buffer' }
        }
    })

    -- TODO try snippets with CLI! sounds like fish abbrs!
    --    https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#ultisnips--cmp-cmdline
    cmp.setup.cmdline(':', {
        mapping = mapping,
        sources = cmp.config.sources({
            { name = 'path' }
        }, {
            { name = 'cmdline' }
        })
    })
end

-- -- FYI these are the original mappings in nvim-cmp
-- https://github.com/hrsh7th/nvim-cmp/blob/b5311ab/lua/cmp/config/mapping.lua#L74
-- local cmdline_mapping = function(override)
--     return merge_keymaps(override or {}, {
--         ['<C-z>'] = {
--             c = function()
--                 local cmp = require('cmp')
--                 if cmp.visible() then
--                     cmp.select_next_item()
--                 else
--                     cmp.complete()
--                 end
--             end,
--         },
--         ['<Tab>'] = {
--             c = function()
--                 local cmp = require('cmp')
--                 if cmp.visible() then
--                     cmp.select_next_item()
--                 else
--                     cmp.complete()
--                 end
--             end,
--         },
--         ['<S-Tab>'] = {
--             c = function()
--                 local cmp = require('cmp')
--                 if cmp.visible() then
--                     cmp.select_prev_item()
--                 else
--                     cmp.complete()
--                 end
--             end,
--         },
--         ['<C-n>'] = {
--             c = function(fallback)
--                 local cmp = require('cmp')
--                 if cmp.visible() then
--                     cmp.select_next_item()
--                 else
--                     fallback()
--                 end
--             end,
--         },
--         ['<C-p>'] = {
--             c = function(fallback)
--                 local cmp = require('cmp')
--                 if cmp.visible() then
--                     cmp.select_prev_item()
--                 else
--                     fallback()
--                 end
--             end,
--         },
--         ['<C-e>'] = {
--             c = mapping.abort(),
--         },
--         ['<C-y>'] = {
--             c = mapping.confirm({ select = false }),
--         },
--     })
-- end
--

return M
