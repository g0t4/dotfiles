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

--- safe table concat for non-array tables
---@generic T : string  # TODO any? using tostring(v)
---@param t table<T, _>
---@param separator string|nil
---@return string
function M.concatKeys(t, separator)
    separator = separator or ", "
    local result = {}
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
    return table.concat(result, separator)
end

--- safe table concat for non-array tables
---@generic T : string  # TODO any? using tostring(v)
---@param t table<_, T>
---@param separator string|nil
---@return string
function M.concatValues(t, separator)
    -- table.concat only works for array tables (integer, consecutive keys that start at 1)
    --   so lets make the same thing but use pairs so we don't miss any items
    --   and we concat the values
    separator = separator or ""
    local result = {}
    for _, v in pairs(t) do
        table.insert(result, v)
    end
    return table.concat(result, separator)
end

--- count the number of items in the table (safe for non-array tables)
---@param t table<any, any>
---@return integer
function M.count(t)
    local count = 0
    M.each(t, function(_key, _value)
        count = count + 1
    end)
    return count
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
---@generic TKey: string|integer
---@generic TValue: any
---@param t table<TKey, TValue>
---@param fn fun(key: TKey, value: TValue)
function M.each(t, fn)
    for k, v in pairs(t) do
        fn(k, v)
    end
end

---@generic T
---@param t table<_, T>
---@param fn fun(value: T)
function M.eachValue(t, fn)
    for _, v in pairs(t) do
        fn(v)
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

--- clone the table container only (keys/values are preserved)
---@generic TKey: string|integer
---@generic TValue: any
---@param t table<TKey, TValue>
---@return table<TKey, TValue>
function M.shallowCopyTable(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

--- returns a new table with only the values that pass the predicate
---@generic TKey: any
---@generic TValue: any
---@param t table<TKey, TValue>
---@param kvPredicate fun(key: TKey, value: TValue): boolean
---@return table<TKey, TValue>
function M.where(t, kvPredicate)
    local result = {}
    for k, v in pairs(t) do
        if kvPredicate(k, v) then
            result[k] = v
        end
    end
    return result
end

--- predicate on value only
---@generic TKey: any
---@generic TValue: any
---@param t table<TKey, TValue>
---@param valuePredicate fun(value: TValue): boolean
---@return table<TKey, TValue>
function M.whereValues(t, valuePredicate)
    return M.where(t, function(_key, value)
        return valuePredicate(value)
    end)
end

--- predicate on key only
---@generic TKey: any
---@generic TValue: any
---@param t table<TKey, TValue>
---@param keyPredicate fun(key: TKey): boolean
---@return table<TKey, TValue>
function M.whereKeys(t, keyPredicate)
    return M.where(t, function(key, _value)
        return keyPredicate(key)
    end)
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
