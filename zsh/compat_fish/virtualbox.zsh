# typographic dyslexia: I find myself typing `vmb` often so lets double alias to that too!
# TODO - use 'vm' instead of 'vbm'/'vmb'? no vagrant subcommand starts with `m` though could collide in future?
# FYI this is used on macos only currently, only move universal if needed (right now WSL is primary linux env so I don't need this)

abbr vboxmanage "VBoxManage"
# NOTE - these conflict with vagrant alias namespace of 'v' but I think this is fine if prefixed deep enough to avoid overlap... try vbm (VBoxManage) # if not try vbox? or vboxm?
abbr vbm "VBoxManage"
  abbr vmb "VBoxManage"
abbr vbmls "VBoxManage list vms"
  abbr vmbls "VBoxManage list vms"
abbr vbmlsr "VBoxManage list runningvms"
  abbr vmblsr "VBoxManage list runningvms"
#  abbr vmblsn "VBoxManage list natnets && VBoxManage list hostonlynets && VBoxManage list intnets"

# FYI these aliases could use placeholders
abbr vbms "VBoxManage showvminfo --machinereadable" # vmname
  abbr vmbs "VBoxManage showvminfo --machinereadable" # vmname
abbr vbme "VBoxManage getextradata" # vmname [key]
  abbr vmbe "VBoxManage getextradata" # vmname [key]
abbr vbmse "VBoxManage setextradata" # vmname KEY VALUE
  abbr vmbse "VBoxManage setextradata" # vmname KEY VALUE

# FYI
# --machinereadable maps better to modifyvm/controlvm parameters: lose indented hierarch, gain common prefix hierarchy -- IIRC some options still don't match modifyvm/controlvm keys, so just be cautious - that said I can't recall which ones - just a warning if so (maybe I am wrong - todo)
# controlvm # change select settings on a running VM - subset of modifyvm settings
# modifyvm # change settings on a stopped VM
