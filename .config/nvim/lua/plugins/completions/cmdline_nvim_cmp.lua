local M = {}


function M.setup()
    local cmp = require('cmp') -- only load if needed

    -- note: I like that it doesn't show until first char typed (by default)

    -- FYI incorrect mappings are silently ignored, USE :cmap to verify first (don't try to invoke the keymaps until cmap is correct)
    --   FYI { c = func } is for cmdline mode mappings, whereas { i = func } is for insert mode in buffer
    --      use cmp.mapping(func, { 'c', 'i' } ) -- instead of { c = func, i = func }
    --      see docs, they cover alot of it in examples
    --
    -- local mapping = {
    --     -- *** GAH I hate up/down mapped to drop down b/c then I can't up arrow through command history so don't do this at all, there is a reason wilder doesn't have that!!!
    --     --   *** learn defaults for moving up/down thru list items
    --     -- ['<Up>'] = { c = cmp.mapping.select_prev_item() }, -- FYI select_prev_item returns a func
    --     -- ['<Down>'] = { c = cmp.mapping.select_next_item() },
    --     -- ['<PageUp>'] = { c = cmp.mapping.scroll_docs(-4) },
    --     -- ['<PageDown>'] = { c = cmp.mapping.scroll_docs(4) },
    -- }
    local mapping = cmp.mapping.preset.cmdline() -- for now this is fine
    -- ok these work, but do I really need them, I should just be fuzzy matching to narrow down list, right?
    -- can I get line #s show to impl page down / up?
    -- also could impl Ctrl-D/U to scroll half page... in cmap Ctrl-D doesn't seem useful
    -- TODO get line numbers and use that?
    function get_half_screen_height_lines()
        return math.floor((vim.o.lines - vim.o.cmdheight) / 2)
    end

    -- function get_screen_height_lines()
    --     return vim.o.lines - vim.o.cmdheight
    -- end

    mapping['<up>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' })
    mapping['<down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' })
    mapping['<C-d>'] = cmp.mapping(cmp.mapping.select_next_item({ count = get_half_screen_height_lines() }),
        { 'c' })
    mapping['<C-u>'] = cmp.mapping(cmp.mapping.select_prev_item({ count = get_half_screen_height_lines() }),
        { 'c' })
    -- mapping['<PageUp>'] = cmp.mapping(cmp.mapping.select_prev_item({ count = get_screen_height_lines() }),
    --     { 'c' })
    -- mapping['<PageDown>'] = cmp.mapping(cmp.mapping.select_next_item({ count = get_screen_height_lines() }),
    --     { 'c' })
    print(vim.inspect(mapping))

    cmp.setup.cmdline({ '/', '?' }, {
        mapping = mapping, -- FYI have to set here too, else <TAB> won't work to tab complete or step through the list
        sources = {
            { name = 'buffer' }
        }
    })

    -- TODO try snippets with CLI! sounds like fish abbrs!
    --    https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#ultisnips--cmp-cmdline
    cmp.setup.cmdline(':', {
        -- apparently, command line mapping is not possible to make it just for `:` but has to be unified with `/` and `?`
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
