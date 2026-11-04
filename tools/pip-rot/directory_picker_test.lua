-- Run from the repository root: lua tools/pip-rot/directory_picker_test.lua
local function element(id, children)
    return { attributeValue=function(_, key)
        if key == 'AXIdentifier' then return id end
        if key == 'AXChildren' then return children or {} end
    end, isValid=function() return true end }
end
local panel = element('save-panel')
local focused = element(nil, {panel})
local front = {activate=function() end}
local launched, callback, eventHandler, bound, scheduled, copied
package.loaded['config.logs'] = {hammerspoons=function() return {error=function() end} end}
package.loaded['config.launcher.pip_rot'] = {open=function(path) launched=path end}
hs = {
    axuielement={applicationElement=function() return {attributeValue=function() return focused end} end},
    application={frontmostApplication=function() return front end},
    fs={attributes=function(path) return path == '/valid folder' and 'directory' or nil end},
    alert={show=function() end},
    json={decode=function(text)
        if text == 'valid' then return {path='/valid folder'} end
        if text == 'copy' or text == 'open' or text == 'unknown' then return {path='/valid folder',action=text} end
        return {}
    end},
    pasteboard={setContents=function(path) copied=path end},
    task={new=function(_, fn)
        callback=fn
        return {start=function() return true end, terminate=function() end}
    end},
    keycodes={map={p=35}},
    hotkey={bind=function(mods,key,fn)
        bound={mods=mods,key=key,fn=fn}
        return {delete=function() end}
    end},
    eventtap={event={types={keyDown=10}},new=function(_,fn)
        eventHandler=fn
        return {start=function(self) return self end,stop=function() end}
    end},
    timer={doAfter=function(_,fn) scheduled=fn end},
}
local picker = assert(loadfile('.config/hammerspoon/config/launcher/directory_picker.lua'))()
assert(picker.panel(front)==panel, 'attached save panel not detected')
focused=element('open-panel')
assert(picker.panel(front)==focused, 'open panel not detected')
focused=element(nil)
assert(picker.panel(front)==nil, 'ordinary window treated as panel')
picker.init()
assert(bound.key=='p' and table.concat(bound.mods,'+')=='ctrl+alt')
local function event(flags)
    return {getFlags=function() return flags end,getKeyCode=function() return 35 end}
end
assert(not eventHandler(event({ctrl=true})), 'Ctrl+P intercepted outside file panel')
focused=panel
assert(not eventHandler(event({ctrl=true,shift=true})), 'modified Ctrl+P intercepted')
assert(eventHandler(event({ctrl=true})), 'Ctrl+P not intercepted inside file panel')
assert(scheduled)
-- Cancellation and malformed selections must never navigate or open a browser.
local navigated
picker.navigate=function(...) navigated={...} end
picker.show(); callback(0,'',''); assert(not launched and not navigated)
picker.show(); callback(0,'invalid',''); assert(not launched and not navigated)
picker.show(); callback(0,'valid',''); assert(navigated[1]==front and navigated[2]==panel and navigated[3]=='/valid folder')
focused=element(nil)
picker.show(); callback(0,'valid',''); assert(launched=='/valid folder')
focused=panel
navigated=nil; launched=nil
picker.show(); callback(0,'copy','')
assert(copied=='/valid folder' and not navigated and not launched, 'copy must not navigate or open')
picker.show(); callback(0,'open','')
assert(launched=='/valid folder' and not navigated, 'explicit open must bypass panel context')
launched=nil
picker.show(); callback(0,'unknown','')
assert(not launched and not navigated, 'unknown action must not dispatch')
picker.shutdown()
print('PASS: panel detection, conditional Ctrl+P, global binding, cancellation, validation, panel/browser dispatch')
