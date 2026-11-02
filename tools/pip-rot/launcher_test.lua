local noop = function() end
local log = setmetatable({}, {__index = function() return noop end})
package.loaded['config.logs'] = {launcher=function() return log end, hammerspoons=function() return log end}
package.loaded['config.launcher.casing'] = {}
local launched
package.loaded['config.launcher.pip_rot'] = {open=function() launched='home' end, reveal=function(paths) launched=paths[1] end}
local choice, callback
local selected = {path='/tmp/example folder/movie.mp4', text='movie.mp4'}
local chooser = {}
setmetatable(chooser, {__index=function(_, key)
    if key=='query' then return function() return '' end end
    if key=='selectedRowContents' then return function() return selected end end
    if key=='select' then return function() callback(selected) end end
    return function() return chooser end
end})
local shortcut
hs = {
    image={imageFromName=noop},
    chooser={new=function(fn) callback=fn; return chooser end},
    hotkey={new=function(mods,key,fn)
        if key=='return' then shortcut=fn end
        return {enable=noop,delete=noop}
    end},
    eventtap={checkKeyboardModifiers=function() return {} end,
        event={types={keyDown=10}}, new=function() return {start=noop,stop=noop} end},
}
local launcher = assert(loadfile('.config/hammerspoon/config/launcher/init.lua'))()
launcher.show()
assert(shortcut, 'missing shortcut')
shortcut()
assert(launched==selected.path, 'shortcut did not reveal selected path')
launcher.show()
selected={bookmark='pip-rot',text='Open Pip Rot'}
callback(selected)
assert(launched=='home', 'bookmark did not launch home')
print('PASS: shortcut explicitly selects result, preserves intent, dispatches reveal; bookmark opens Home')
