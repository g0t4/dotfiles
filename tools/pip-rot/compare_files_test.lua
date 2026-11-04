local message, callback, command, args
local mode = 'file'
local log = {error=function() end}
package.loaded['config.logs']={launcher=function() return log end}
hs = {
    fs={attributes=function() return mode end},
    alert={show=function(value) message=value end},
    task={new=function(executable, fn, argv)
        command,args,callback=executable,argv,fn
        return {start=function() return true end}
    end},
}
local compare=assert(loadfile('.config/hammerspoon/config/launcher/compare_files.lua'))()
local paths={"/tmp/a $ ' \n",'/tmp/b.mov'}
compare.compare(paths)
assert(command=='/usr/bin/cmp' and args[1]=='-s' and args[2]==paths[1] and args[3]==paths[2])
callback(0); assert(message=='Files are identical')
compare.compare(paths); callback(1); assert(message=='Files differ')
compare.compare(paths); callback(2,'','unreadable'); assert(message=='Could not compare files')
mode='directory'; compare.compare(paths); assert(message=='Select exactly two regular files')
mode='file'
hs.task.new=function() return nil end
compare.compare(paths); assert(message=='Could not start file comparison')
print('PASS: asynchronous cmp argv, identical/different/error, directory rejection, start failure; no clipboard or diff viewer')
-- Status transport goes to the captured Pip Rot PID, even after focus changes.
local written, renamed
local originalOpen, originalRename = io.open, os.rename
hs.json={read=function() return {pid=123, capabilities={'status'}} end,
    encode=function(payload) written=payload; return 'encoded' end}
hs.application={applicationForPID=function(pid) return pid==123 end}
io.open=function() return {write=function() end, close=function() end} end
os.rename=function() renamed=true; return true end
hs.task.new=function(_, fn) callback=fn; return {start=function() return true end} end
compare.compare(paths, {source='pip-rot',pid=123})
callback(1)
io.open, os.rename = originalOpen, originalRename
assert(renamed and written.pid==123 and written.message=='Files differ' and written.warning)
print('PASS: atomic status message targets captured Pip Rot process')
