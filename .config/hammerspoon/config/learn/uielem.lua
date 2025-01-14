-- very thin module... uielement... seems just to be able to get focused element?
--   and then switch to axuielement for more advanced stuff
--
local focusedUIElem = hs.uielement.focusedElement()
print("focusedUIElem", focusedUIElem.__name)
print("metatable: ", hs.inspect(hs.getObjectMetatable("hs.uielement")))

print("focused..", hs.inspect(focusedUIElem, { metatables = true }))
