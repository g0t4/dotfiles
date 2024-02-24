## packer
#if command -q packer # find common if for zsh and fish?
  eabbr pa 'packer'
  eabbr pai 'packer init .'
  eabbr pav 'packer validate .'
  eabbr paf 'packer fmt .'
  eabbr pab 'packer build .'
#end

## vagrant
# https://www.vagrantup.com/docs/experimental
# enable all:
#   export VAGRANT_EXPERIMENTAL=1
# enable feature(s):
#   export VAGRANT_EXPERIMENTAL="feature_one,feature_two"

# DISABLE these for duration of course (so vagrant has default behavior):
# export VAGRANT_BOX_UPDATE_CHECK_DISABLE=1
# export VAGRANT_PROVIDER=virtualbox

#if command -q vagrant
  eabbr v 'vagrant'
  eabbr vlsc 'vagrant list-commands'

  ## Vagrantfile
  eabbr vi 'vagrant init --minimal'
  eabbr vv 'vagrant validate'

  ## cloud boxes
  eabbr vc 'vagrant cloud'
  eabbr vcs 'vagrant cloud search'
  eabbr vcb 'vagrant cloud box show'

  ## local (cached) boxes
  eabbr vb 'vagrant box'
  eabbr vbls 'vagrant box list -i'
  eabbr vba 'vagrant box add'
  eabbr vbo 'vagrant box outdated'
  eabbr vbog 'vagrant box outdated --global'
  eabbr vbu 'vagrant box update' # current vagrant project only
  eabbr vbub 'vagrant box update --box' # independent of project
  eabbr vbpr 'vagrant box prune --dry-run'
  eabbr vbrm 'vagrant box remove'
  eabbr vbrep 'vagrant box repackage'

  # any vbox VM => vagrant box (generates embedded Vagrantfile too)
  eabbr vpack 'vagrant package --base ' # last arg is VM name (see vboxmanage list vms)

  ## query
  eabbr vst 'vagrant status'
  eabbr vgst 'vagrant global-status --prune'

  ## VM state
  eabbr vu 'vagrant up'
  eabbr vpv 'vagrant provision'
  eabbr vh 'vagrant halt'
  eabbr vrl 'vagrant reload'
  eabbr vrlp 'vagrant reload --provision'
  #
  eabbr vsp 'vagrant suspend'
  eabbr vspg 'vagrant suspend --all-global'
  eabbr vrs 'vagrant resume'

  ## cleanup
  eabbr vd 'vagrant destroy'
  eabbr vdf 'vagrant destroy -f'

  ## plugins
  eabbr vp 'vagrant plugin'
    eabbr vpls 'vagrant plugin list'
    eabbr vpi 'vagrant plugin install'
    eabbr vprm 'vagrant plugin uninstall'
    eabbr vpupdate 'vagrant plugin update'

  # connect
  eabbr vs 'vagrant ssh'
  eabbr vsc 'vagrant ssh-config'
  eabbr vscmd 'vagrant ssh --command'
  # TODO add alias to use ssh-config file that is in .vagrant folder with ssh command without needing ssh-config IIRC

  # snapshots
  eabbr vsn 'vagrant snapshot'
  eabbr vsnls 'vagrant snapshot list'
  # named snapshots
  eabbr vsns 'vagrant snapshot save'
  eabbr vsnr 'vagrant snapshot restore'
  eabbr vsnrm 'vagrant snapshot delete'
  # stack based snapshots
  eabbr vsnpu 'vagrant snapshot push'
  eabbr vsnpo 'vagrant snapshot pop'
#end