## packer
#if command -q packer # find common if for zsh and fish?
  abbr pa 'packer'
  abbr pai 'packer init .'
  abbr pav 'packer validate .'
  abbr paf 'packer fmt .'
  abbr pab 'packer build .'
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
  abbr v 'vagrant'
  abbr vlsc 'vagrant list-commands'

  ## Vagrantfile
  abbr vi 'vagrant init --minimal'
  abbr vv 'vagrant validate'

  ## cloud boxes
  abbr vc 'vagrant cloud'
  abbr vcs 'vagrant cloud search'
  abbr vcb 'vagrant cloud box show'

  ## local (cached) boxes
  abbr vb 'vagrant box'
  abbr vbls 'vagrant box list -i'
  abbr vba 'vagrant box add'
  abbr vbo 'vagrant box outdated'
  abbr vbog 'vagrant box outdated --global'
  abbr vbu 'vagrant box update' # current vagrant project only
  abbr vbub 'vagrant box update --box' # independent of project
  abbr vbpr 'vagrant box prune --dry-run'
  abbr vbrm 'vagrant box remove'
  abbr vbrep 'vagrant box repackage'

  # any vbox VM => vagrant box (generates embedded Vagrantfile too)
  abbr vpack 'vagrant package --base ' # last arg is VM name (see vboxmanage list vms)

  ## query
  abbr vst 'vagrant status'
  abbr vgst 'vagrant global-status --prune'

  ## VM state
  abbr vu 'vagrant up'
  abbr vpv 'vagrant provision'
  abbr vh 'vagrant halt'
  abbr vrl 'vagrant reload'
  abbr vrlp 'vagrant reload --provision'
  #
  abbr vsp 'vagrant suspend'
  abbr vspg 'vagrant suspend --all-global'
  abbr vrs 'vagrant resume'

  ## cleanup
  abbr vd 'vagrant destroy'
  abbr vdf 'vagrant destroy -f'

  ## plugins
  abbr vp 'vagrant plugin'
    abbr vpls 'vagrant plugin list'
    abbr vpi 'vagrant plugin install'
    abbr vprm 'vagrant plugin uninstall'
    abbr vpupdate 'vagrant plugin update'

  # connect
  abbr vs 'vagrant ssh'
  abbr vsc 'vagrant ssh-config'
  abbr vscmd 'vagrant ssh --command'
  # TODO add alias to use ssh-config file that is in .vagrant folder with ssh command without needing ssh-config IIRC

  # snapshots
  abbr vsn 'vagrant snapshot'
  abbr vsnls 'vagrant snapshot list'
  # named snapshots
  abbr vsns 'vagrant snapshot save'
  abbr vsnr 'vagrant snapshot restore'
  abbr vsnrm 'vagrant snapshot delete'
  # stack based snapshots
  abbr vsnpu 'vagrant snapshot push'
  abbr vsnpo 'vagrant snapshot pop'
#end