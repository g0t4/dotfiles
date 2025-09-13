local function EnsureCheckboxIsChecked(checkbox)
    if checkbox:attributeValue("AXValue") ~= 0 then
        return
    end
    checkbox:performAction("AXPress")
    if checkbox:attributeValue("AXValue") ~= 1 then
        -- FYI errors look really nice when using hs -c "command" in terminal
        --   AND look good in notifications from Keyboard Maestro when that hs command fails
        --   Line nubmer shows in initial part of message so I can just use that to jump to spot
        --   TODO use error() in more places, basically for failed assertions
        error("checkbox was not checked")
    end
end

local function EnsureCheckboxIsUnchecked(checkbox)
    if checkbox:attributeValue("AXValue") ~= 0 then
        return
    end
    checkbox:performAction("AXPress")
    if checkbox:attributeValue("AXValue") ~= 0 then
        error("checkbox was not unchecked")
    end
end

---@class FcpxInspectorPanel
---@field window FcpxEditorWindow
local FcpxInspectorPanel = {}
FcpxInspectorPanel.__index = FcpxInspectorPanel
function FcpxInspectorPanel:new(window)
    local o = {}
    setmetatable(o, self)
    -- yeah at this point, probably all I can guarantee is that a window exists...
    --   panels need to be opened before any interactions, so defer all of that!
    --   FYI... I will find the right balance for where logic belongs as I use this (window vs this class, etc)
    o.window = window
    return o
end

function FcpxInspectorPanel:ensureOpen()
    -- TODO... can also use menu to show it, from CommandPost:
    -- menuBar:selectMenu({"Window", "Show in Workspace", "Inspector"})
    -- https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L261

    EnsureCheckboxIsChecked(self.window.topToolbar.btnInspector)
end

function FcpxInspectorPanel:ensureClosed()
    EnsureCheckboxIsUnchecked(self.window.topToolbar.btnInspector)
end

function FcpxInspectorPanel:topBarCheckboxByDescription(matchDescription)
    local startTime = get_time()

    local candidates = self.window:rightSidePanel():group(2):checkBoxes()
    -- OUCH 11ms! ... IIUC b/c its cloning axuielements using CopyAttributeValue("AXChildren") every time!
    print("candidates: ", hs.inspect(candidates))
    print("time to index cbox: " .. get_elapsed_time_in_milliseconds(startTime) .. " ms")

    for _, candidate in ipairs(candidates) do
        if candidate:attributeValue("AXDescription") == matchDescription then
            print("time to found cbox: " .. get_elapsed_time_in_milliseconds(startTime) .. " ms")
            print("found fixed path to title panel checkbox")
            return candidate
        end
    end

    print("time to search failed: " .. get_elapsed_time_in_milliseconds(startTime) .. " ms")
    error("Could not find checkbox for description: " .. matchDescription)
end

function FcpxInspectorPanel:titleCheckbox()
    -- INCORPORATE WORKING SEARCH CODE INSTEAD, see "x scrubber" streamdeck button's code:
    --    fcpx.init => FcpxFindInspectorPanelViaTitleCheckbox (FYI might be renamed)

    -- FIXED PATH CURRENTLY (this seems to have changed, extra splitgroup.. if so lets try search to find it going forward, nested under right panel which s/b mostly fixed in place)
    --
    -- longer path I found a few times:
    --    PRN recapture this using hammerspoon lua specifier...
    --    set Title to checkbox 1 of group 2 of group 5 of splitter group 1 of group 2 of ¬
    --      splitter group 1 of group 1 of splitter group 1 of window "Final Cut Pro" of ¬
    --        application process "Final Cut Pro"
    -- attrs:
    --   AXActivationPoint = {y=55.0, x=1537.0}
    --   AXDescription = "Title Inspector"
    --   AXEnabled = true
    --   AXFocused = false
    --   AXFrame = {y=44.0, h=20.0, w=20.0, x=1527.0}
    --   AXHelp = "Show the Title Inspector"
    --   AXIdentifier = "_NS:10"
    --   AXPosition = {y=44.0, x=1527.0}
    --   AXRole = "AXCheckBox"
    --   AXRoleDescription = "toggle button"
    --   AXSize = {w=20.0, h=20.0}
    --   AXSubrole = "AXToggle"
    --   AXTitle = "Title"
    --   AXValue = 1

    return self:topBarCheckboxByDescription("Title Inspector")

    -- btw CommandPost goes off of AXTitle:
    --   https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L359
    --   ALSO, uses localized (IIUC) strings to find the title match: FFInspectorTabMotionEffectTitle
end

function FcpxInspectorPanel:titleCheckboxSearch()
    FindOneElement(self.window:rightSidePanel(),
        { attribute = "AXDescription", value = "Title Inspector" },
        function(_, searchTask, numResultsAdded)
            if numResultsAdded == 0 then
                error("Could not find title inspector checkbox")
            end
            return searchTask[1]
        end)
end

function FcpxInspectorPanel:showTitleInspector()
    self:ensureOpen()
    EnsureCheckboxIsChecked(self:titleCheckbox())
    -- self:titleCheckboxSearch() -- test timing only
end

return FcpxInspectorPanel
