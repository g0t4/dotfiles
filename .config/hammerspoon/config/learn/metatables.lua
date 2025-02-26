local Foo = {
    name = "foo",
    foo2 = "foo2"
}

print("Foo:", hs.inspect(Foo))

local Bar = {
    name = "bar"
}

print("Bar:", hs.inspect(Bar))

Bar.__index = Foo
print("Bar.foo2:", Bar.foo2) -- nil

setmetatable(Bar, Foo)
print("Bar.foo2:", Bar.foo2) -- nil

setmetatable(Bar, { __index = Foo })
print("Bar.foo2:", Bar.foo2) -- "foo2"

-- I think I wanna avoid using Foo.__index on ANYTHING... it is very confusing
--   instead when setting a metatable, always, always use { __index = X }
--   that way I never forget the METATABLE'S __index is only used for undefined keys
Foo.__index = Foo
setmetatable(Bar, Foo)
print("Foo.foo2:", Foo.foo2) -- "foo2"



local generic = {}
print("gen", generic) -- ==> "table ..."
setmetatable(generic, { __tostring = function(self) return "gen" end })
print("gen2", generic) -- => "gen" since __tostring is directly defined on metatable
local child = setmetatable({}, { __index = generic })
print("child", child) -- => "table ..." b/c __tostring IS NOT SUBJECT TO INDEX LOOKUP (can only be defined directly on metatable of a given table)
local child = setmetatable({}, { __index = generic, __tostring = function(self) return "chill" end })
print("child2", child) -- => "chill" since __tostring is directly defined
