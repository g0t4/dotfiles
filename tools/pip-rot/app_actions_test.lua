local noop = function() end
local log = setmetatable({}, {__index=function() return noop end})
package.loaded['config.logs']={hammerspoons=function() return log end}
local context={source='pip-rot',pid=123,capabilities={'restart'}}
local live=context
local written, destination
hs={image={imageFromName=noop},alert={show=noop},
    json={read=function() return live end,encode=function(request)
        assert(request.version==1 and request.pid==123 and request.command=='restart')
        return 'encoded restart request'
    end},application={applicationForPID=function(pid) return pid==123 and {} end}}
local handler=assert(loadfile('.config/hammerspoon/config/launcher/app_actions.lua'))()
assert(#handler.choices({source='finder'})==0)
assert(#handler.choices({source='pip-rot'})==0)
local choices=handler.choices(context)
assert(choices[1].action=='restart_app' and choices[1].app_context==context)
local savedOpen,savedRename=io.open,os.rename
io.open=function(path,mode)
    assert(path:match('/request%-123.json.tmp$') and mode=='w')
    return {write=function(_,value) written=value end,close=noop}
end
os.rename=function(source,target) destination=target;return true end
assert(handler.restart(context))
assert(written=='encoded restart request' and destination:match('/request%-123.json$'))
live={source='pip-rot',pid=999,capabilities={'restart'}}
assert(not handler.restart(context))
io.open,os.rename=savedOpen,savedRename
print('PASS: per-app capability gating, restart request payload, atomic publication, stale PID rejection')

local powerpoint={source='powerpoint',pid=456,capabilities={'restart'}}
local running, quit, launches, stopped=true,0,0,0
local poll
local app={bundleID=function() return 'com.microsoft.Powerpoint' end,
    kill=function() quit=quit+1 end}
hs.application.applicationForPID=function(pid) return pid==456 and running and app or nil end
hs.application.launchOrFocusByBundleID=function(id)
    assert(id=='com.microsoft.Powerpoint'); launches=launches+1; return true
end
hs.timer={doEvery=function(interval, callback)
    assert(interval==0.2); poll=callback
    return {stop=function() stopped=stopped+1 end}
end}
assert(handler.choices(powerpoint)[1].subText:match('PowerPoint'))
assert(handler.restart(powerpoint) and quit==1)
assert(not handler.restart(powerpoint), 'duplicate restart must be rejected')
poll(); assert(launches==0, 'must wait for graceful quit and save prompts')
running=false; poll(); assert(launches==1 and stopped==1)
assert(not handler.restart(powerpoint), 'stale PID must be rejected')
running=true
assert(handler.restart(powerpoint))
for _=1,300 do poll() end
assert(launches==1 and stopped==2, 'canceled or pending quit must not relaunch')
app.bundleID=function() return 'com.apple.finder' end
assert(not handler.restart(powerpoint), 'PID belonging to another app must be rejected')
print('PASS: PowerPoint graceful quit, duplicate/stale PID guards, exit-before-relaunch, canceled quit timeout')
