-- FYI based on https://github.com/mirven/underscore.lua/blob/master/lib/underscore.lua?
--   but with my fixes/changes

-- *** my own underscore impl
-- define globally so I don't need to split out a module, or aggregate it into other helpers as a module
local M = {}

--- works on all tables, but does not guarantee order
--- I added this b/c underscore.lua has broken detection of array/map
---   i.e. hs.axuilement.observer.notifications is not an array, but it treats it as such and thus appears empty
--- if you want ipairs semantics, use imap (uses ipairs under the hood)
---@param t table
---@param fn function
---@return table
function M.map(t, fn)
    local result = {}
    for k, v in pairs(t) do
        result[k] = fn(v)
    end
    return result
end

--- returns array of keys (values are dropped)
---@param t table
---@return table<integer, string>
function M.keys(t)
    local result = {}
    M.each(t, function(key, _value)
        table.insert(result, key)
    end)
    return result
end

--- returns array of values (keys are dropped)
---@param t table
---@return table<integer, any>
function M.values(t)
    local result = {}
    M.each(t, function(_key, value)
        table.insert(result, value)
    end)
    return result
end

--- preserves order for arrays only (integer, consecutive keys) (uses ipairs)
---   [i]map => [i]pairs
---@param t table
---@param fn function
---@return table
function M.imap(t, fn)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = fn(v)
    end
    return result
end

--- works on all tables, but does not guarantee order (uses pairs)
--- usage:
---
---   M.each(hs.axuielement.observer.notifications, function(key, value)
---       print(" " .. key .. " => " .. value)
---   end)
---
---   M.each({ foo = "bar", baz = "qux" }, function(key, _)
---       print(key)
---   end)
---
---@param t table
---@param fn fun(key: string|integer, value: any)
function M.each(t, fn)
    for k, v in pairs(t) do
        fn(k, v)
    end
end

--- preserves order for arrays only (integer, consecutive keys) (uses ipairs)
function M.ieach(t, fn)
    for i, v in ipairs(t) do
        fn(v, i)
    end
end

--- preserves order for arrays only (integer, consecutive keys) (uses ipairs)
function M.ieachKey(t, fn)
    for i, v in ipairs(t) do
        fn(v, i)
    end
end

-- *** MISC table operations
--  TODO migrate to underscore equivalents above
--  FYI DO NOT TRY TO EXPORT THESE from this module, instead split them out if you need that.

--   some use fun.lua
local fun = require("fun")
-- TODO break away from fun.lua too (it barely had anything useful anyways)

function EnumTableValues(tbl)
    return fun.enumerate(tbl):map(function(key, value)
        return value
    end)
end

function TableLeftJoin(theTable, separator)
    -- FYI just to get a bit of practice using luafun library
    --  surprised to find it provides very few methods (i.e. no reverse)
    return EnumTableValues(theTable)
        :foldl(function(accum, current)
            if accum == "" then
                -- don't join nothing with first entry
                return current
            end
            return accum .. separator .. current
        end, "")
end

function TableReverse(theTable)
    -- just for practice
    local reversed = {}
    for _, v in pairs(theTable) do
        table.insert(reversed, 1, v)
    end
    return reversed
end

function TableContains(theTable, value)
    for _, v in pairs(theTable) do
        if v == value then return true end
    end
    return false
end

-- chainable too, perhaps add more overloads with builder pattern of chaining (return tablej)
function table_prepend(theTable, value)
    table.insert(theTable, 1, value)
    return theTable
end

return M
