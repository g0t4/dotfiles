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
