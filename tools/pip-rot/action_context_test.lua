local noop = function() end
local log = setmetatable({}, {__index=function() return noop end})
package.loaded['config.logs'] = {hammerspoons=function() return log end, launcher=function() return log end}
local title = '/tmp — Pip Rot'
local payload = {version=1, kind='files', source='pip-rot', pid=123,
    window_title=title, paths={"/tmp/a $ ' file"}}
local app = {bundleID=function() return nil end, pid=function() return 123 end,
    focusedWindow=function() return {title=function() return title end} end}
local actions, callback, task_args
hs = {
    application={frontmostApplication=function() return app end},
    json={read=function() return payload end},
    image={imageFromName=noop, imageFromPath=noop},
    fs={attributes=function(path, key)
        local attrs = {mode='file', size=12, modification=os.time()}
        return key and attrs[key] or attrs
    end},
    alert={show=noop},
    task={new=function(_, _, args) task_args=args; return {start=function() return true end} end},
    chooser={new=function(fn)
        callback=fn
        return setmetatable({}, {__index=function(_, key)
            if key=='choices' then return function(_, value) actions=value end end
            return noop
        end})
    end},
}
local provider = assert(loadfile('.config/hammerspoon/config/launcher/action_context.lua'))()
assert(provider.capture() == payload)
payload.pid=999; assert(provider.capture()==nil); payload.pid=123
payload.window_title='wrong'; assert(provider.capture()==nil); payload.window_title=title
local real_title=title; title='not Pip Rot'; assert(provider.capture()==nil); title=real_title
package.loaded['config.launcher.action_context']=provider
package.loaded['config.launcher.app_actions']={choices=function() return {} end}
local file_actions=assert(loadfile('.config/hammerspoon/config/launcher/file_actions.lua'))()
file_actions.show()
for _, action in ipairs(actions) do assert(action.action~='trash', 'root fallback must not offer Trash') end
payload.selection_explicit=true
file_actions.show()
local trash
for _, action in ipairs(actions) do if action.action=='trash' then trash=action end end
assert(trash, 'explicit selection must offer Trash')
callback(trash)
assert(task_args[1]=='-F' and task_args[2]==payload.paths[1])
local terminal
for _, action in ipairs(actions) do if action.action=='open_terminal' then terminal=action end end
assert(terminal.context_source=='pip-rot')
assert(terminal.paths[1]==payload.paths[1])
-- Selection is captured before the picker activates, and survives later updates.
payload={version=1,kind='files',source='pip-rot',pid=123,window_title=title,paths={'/different'}}
callback(terminal)
assert(task_args[1]=='-a' and task_args[2]=='iTerm' and task_args[3]=='/tmp')
app.bundleID=function() return 'com.apple.finder' end
hs.osascript={applescript=function() return true, {'/tmp/new\nline/', '/'} end}
local finder=provider.capture()
assert(finder.source=='finder' and finder.paths[1]=='/tmp/new\nline' and finder.paths[2]=='/')
print('PASS: context validation, wrong PID/window rejection, picker snapshot, Terminal args, Finder list preserves newlines and root')

local created = {}
hs.dialog={textPrompt=function() return 'Create', "new/child $ ' name" end}
hs.fs.attributes=function(path) return path=='/tmp' and {mode='directory'} or nil end
hs.fs.mkdir=function(path) table.insert(created,path); return true end
callback({action='new_nested_folder',context_source='pip-rot',paths={'/tmp'}})
assert(created[1]=='/tmp/new' and created[2]=="/tmp/new/child $ ' name")
print('PASS: picker creates nested directories from captured parent')

app.bundleID=function() return 'com.microsoft.Powerpoint' end
local powerpoint=provider.capture()
assert(powerpoint.kind=='app' and powerpoint.source=='powerpoint' and powerpoint.pid==123)
assert(#powerpoint.paths==0 and powerpoint.capabilities[1]=='restart')
print('PASS: PowerPoint app-only restart context')
