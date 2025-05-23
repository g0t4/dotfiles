local FcpxInspectorPanel = require("config.macros.fcpx.inspector_panel")
local FcpxTopToolbar = require("config.macros.fcpx.top_toolbar")

---@class FcpxEditorWindow
---@field window hs.axuielement
---@field fcpx hs.axuielement
---@field topToolbar FcpxTopToolbar
---@field inspector FcpxInspectorPanel
local FcpxEditorWindow = {}
FcpxEditorWindow.__index = FcpxEditorWindow

function FcpxEditorWindow:new()
    local o = {}
    setmetatable(o, self)
    o.window, o.fcpx = GetFcpxEditorWindow()
    o.topToolbar = FcpxTopToolbar:new(o.window:childrenWithRole("AXToolbar")[1])
    -- everything below top toolbar
    -- use _ to signal that it's not guaranteed to be there
    o._mainSplitGroup = o.window:childrenWithRole("AXSplitGroup")[1]
    print("main split group", hs.inspect(o._mainSplitGroup))
    o.inspector = FcpxInspectorPanel:new(o)
    return o
end

function FcpxEditorWindow:rightSidePanel()
    -- FYI if overhead in lookup on every use, can memoize this... but not until I have proof its an issue.. and probabaly only for situations where 10ms is a problem
    -- FOR NOW... defer everything beyond the window!
    -- TODO this group is varying...  CAN I query smth like # elements and find what I want that way?
    return self._mainSplitGroup:group(2)
end

function FcpxEditorWindow:rightSidePanelTopBar()
    -- TODO this group is varying...
    return self:rightSidePanel():group(2)
end

function FcpxEditorWindow:leftSideEverythingElse()
    -- TODO use and rename this... b/c its not a left side panel, it's the rest of the UI (browser,timeline,events viewer,titles,generators,etc) - everything except the inspector (in my current layout)
    -- TODO this group is varying...
    return self._mainSplitGroup:group(1)
end

return FcpxEditorWindow
