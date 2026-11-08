local M = {}


function M.setup()
    local cmp = require('cmp')

    -- note: I like that it doesn't show until first char typed (by default)

    local suggested_mapping = cmp.mapping.preset.cmdline()

    local function get_half_screen_height_lines()
        return math.floor((vim.o.lines - vim.o.cmdheight) / 2)
    end

    -- now I build a new mapping based on selected mappings from preset that I want
    local mapping = {}
    mapping['<Tab>'] = suggested_mapping['<Tab>']
    mapping['<S-Tab>'] = suggested_mapping['<S-Tab>']
    -- Discard the old request before editing backwards or moving away from
    -- its anchor. Deletion requests the remaining word afresh;
    -- cursor-only movement simply leaves the menu closed.
    for _, key in ipairs({
        '<BS>', '<C-h>', '<C-w>', '<Left>', '<Right>', '<S-Left>', '<S-Right>',
        '<C-Left>', '<C-Right>', '<Home>', '<End>', '<C-b>', '<C-e>',
        '<Up>', '<Down>', '<C-p>', '<C-n>', '<Del>',
    }) do
        mapping[key] = cmp.mapping(function(fallback)
            cmp.close()
            fallback()
            if key == '<BS>' or key == '<C-h>' or key == '<C-w>' or key == '<Del>' then
                -- close() briefly suspends cmp. Wait for its release and the
                -- native edit before requesting candidates at the new cursor.
                vim.schedule(function()
                    vim.schedule(function()
                        local kind = vim.fn.getcmdtype()
                        if kind ~= '/' and kind ~= '?' and kind ~= ':' then return end
                        local before = vim.fn.getcmdline():sub(1, vim.fn.getcmdpos() - 1)
                        if before:match('%S$') then cmp.complete() end
                    end)
                end)
            end
        end, { 'c' })
    end
    --
    -- CRAP that's right... these steal my ability to move up/down in command history when completion is visible.. which is like always
    -- mapping['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'c' })
    -- mapping['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'c' })
    --
    -- move up/down by half screen height # of lines
    mapping['<C-D>'] = cmp.mapping(cmp.mapping.select_next_item({ count = get_half_screen_height_lines() }), { 'c' })
    mapping['<C-U>'] = cmp.mapping(cmp.mapping.select_prev_item({ count = get_half_screen_height_lines() }), { 'c' })
    -- vim.print(mapping)

    local function requested_explicitly(entry, ctx)
        return entry.context:get_reason() == cmp.ContextReason.Manual
            and entry.context.cursor_before_line == ctx.cursor_before_line
    end
    local function has_prefix(entry, ctx)
        return requested_explicitly(entry, ctx)
            or ctx.cursor_before_line:match('%S$') ~= nil
    end

    cmp.setup.cmdline({ '/', '?' }, {
        -- FYI appears that this can be different from mapping for cmdline below
        mapping = mapping,
        sources = {
            {
                name = 'buffer',
                entry_filter = function(entry, ctx)
                    if requested_explicitly(entry, ctx) then return true end
                    local offset = ctx:get_offset(entry.source:get_keyword_pattern())
                    -- Cached candidates must belong to the word at the current
                    -- cursor, never an empty prefix after a separator.
                    return offset < ctx.cursor.col and entry.offset == offset
                end,
            }
        }
    })

    -- TODO try snippets with CLI! sounds like fish abbrs!
    --    https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#ultisnips--cmp-cmdline
    cmp.setup.cmdline(':', {
        mapping = mapping,
        sources = cmp.config.sources({
            { name = 'path', entry_filter = has_prefix }
        }, {
            { name = 'cmdline', entry_filter = has_prefix }
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
