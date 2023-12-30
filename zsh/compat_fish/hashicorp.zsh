## packer
ealias pa='packer'
ealias pai='packer init .'
ealias pav='packer validate .'
ealias paf='packer fmt .'
ealias pab='packer build .'

## vagrant
# https://www.vagrantup.com/docs/experimental
# enable all:
#   export VAGRANT_EXPERIMENTAL=1
# enable feature(s):
#   export VAGRANT_EXPERIMENTAL="feature_one,feature_two"

# DISABLE these for duration of course (so vagrant has default behavior):
# export VAGRANT_BOX_UPDATE_CHECK_DISABLE=1
# export VAGRANT_PROVIDER=virtualbox

ealias v='vagrant'
ealias vlsc='vagrant list-commands'

## Vagrantfile
ealias vi='vagrant init --minimal'
ealias vv='vagrant validate'

## cloud boxes
ealias vc='vagrant cloud'
ealias vcs='vagrant cloud search'
ealias vcb='vagrant cloud box show'

## local (cached) boxes
ealias vb='vagrant box'
ealias vbls='vagrant box list -i'
ealias vba='vagrant box add'
ealias vbo='vagrant box outdated'
ealias vbog='vagrant box outdated --global'
ealias vbu='vagrant box update' # current vagrant project only
ealias vbub='vagrant box update --box' # independent of project
ealias vbpr='vagrant box prune --dry-run'
ealias vbrm='vagrant box remove'
ealias vbrep='vagrant box repackage'

# any vbox VM => vagrant box (generates embedded Vagrantfile too)
ealias vpack='vagrant package --base ' # last arg is VM name (see vboxmanage list vms)

## query
ealias vst='vagrant status'
ealias vgst='vagrant global-status --prune'

## VM state
ealias vu='vagrant up'
ealias vpv='vagrant provision'
ealias vh='vagrant halt'
ealias vrl='vagrant reload'
ealias vrlp='vagrant reload --provision'
#
ealias vsp='vagrant suspend'
ealias vspg='vagrant suspend --all-global'
ealias vrs='vagrant resume'

## cleanup
ealias vd='vagrant destroy'
ealias vdf='vagrant destroy -f'

## plugins
ealias vpl='vagrant plugin'
  ealias vplls='vagrant plugin list'
# include local plugins in list
  ealias vpllsl='vagrant plugin list --local'
  ealias vplup='vagrant plugin update'
# installing plugins
  ealias vpli='vagrant plugin install'
  ealias vplil='vagrant plugin install --local'
  ealias vplun='vagrant plugin uninstall'

# connect
ealias vs='vagrant ssh'
ealias vsc='vagrant ssh-config'
ealias vscmd='vagrant ssh --command'
# TODO add alias to use ssh-config file that is in .vagrant folder with ssh command without needing ssh-config IIRC

# snapshots
ealias vsn='vagrant snapshot'
ealias vsnls='vagrant snapshot list'
# named snapshots
ealias vsns='vagrant snapshot save'
ealias vsnr='vagrant snapshot restore'
ealias vsnrm='vagrant snapshot delete'
# stack based snapshots
ealias vsnpu='vagrant snapshot push'
ealias vsnpo='vagrant snapshot pop'
