
--
-- !!! ... can't get app/window.. only "focusedElement" ... and no events work on it..
--   IIAC this is a predecessor to AXUIElement? and so I should avoid UIElement?
--- TRY hs.uielement.watcher if I have issues with axuielement.observer
-- https://www.hammerspoon.org/docs/hs.uielement.watcher.html
--   window[Moved|Resized|Minimized|Unminimized]
--   titleChanged, elementDestroyed
--   mainWindowChanged, focusedWindowChanged, focusedElementChanged
local focused = hs.uielement.focusedElement()
print("focused", hs.inspect(focused.__name))
print("  getmetatable:", hs.inspect(getmetatable(focused)))
print("  role:", hs.inspect(focused:role()))
print("  selectedText:", hs.inspect(focused:selectedText()))
print("  isWindow:", hs.inspect(focused:isWindow()))
print("  isApplication:", hs.inspect(focused:isApplication()))
--
focused:newWatcher(
---@param element hs.uielement
---@param event string
---@param _watcher hs.uielement.watcher
---@param _userData table|nil # passed to newWatcher (after this func)
    function(element, event, _watcher, _userData)
        print("watcher", event, hs.inspect(element))
    end,
    -- userData
    {
        -- i.e.? to cancnel the watcher?
        -- cancel = function() end,
    }
)


