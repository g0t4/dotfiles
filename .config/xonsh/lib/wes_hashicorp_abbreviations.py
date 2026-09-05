"""Generated from zsh/compat_fish/hashicorp.zsh."""

from __future__ import annotations

from wes_abbreviations import abbr


def register_hashicorp_abbreviations():
    abbr('pa', 'packer')  # HashiCorp line 3
    abbr('pai', 'packer init .')  # HashiCorp line 4
    abbr('pav', 'packer validate .')  # HashiCorp line 5
    abbr('paf', 'packer fmt .')  # HashiCorp line 6
    abbr('pab', 'packer build .')  # HashiCorp line 7
    abbr('v', 'vagrant')  # HashiCorp line 22
    abbr('vlsc', 'vagrant list-commands')  # HashiCorp line 23
    abbr('vi', 'vagrant init --minimal')  # HashiCorp line 26
    abbr('vv', 'vagrant validate')  # HashiCorp line 27
    abbr('vc', 'vagrant cloud')  # HashiCorp line 30
    abbr('vcs', 'vagrant cloud search')  # HashiCorp line 31
    abbr('vcb', 'vagrant cloud box show')  # HashiCorp line 32
    abbr('vb', 'vagrant box')  # HashiCorp line 35
    abbr('vbls', 'vagrant box list -i')  # HashiCorp line 36
    abbr('vba', 'vagrant box add')  # HashiCorp line 37
    abbr('vbo', 'vagrant box outdated')  # HashiCorp line 38
    abbr('vbog', 'vagrant box outdated --global')  # HashiCorp line 39
    abbr('vbu', 'vagrant box update')  # HashiCorp line 40
    abbr('vbub', 'vagrant box update --box')  # HashiCorp line 41
    abbr('vbpr', 'vagrant box prune --dry-run')  # HashiCorp line 42
    abbr('vbrm', 'vagrant box remove')  # HashiCorp line 43
    abbr('vbrep', 'vagrant box repackage')  # HashiCorp line 44
    abbr('vpack', 'vagrant package --base ')  # HashiCorp line 47
    abbr('vst', 'vagrant status')  # HashiCorp line 50
    abbr('vgst', 'vagrant global-status --prune')  # HashiCorp line 51
    abbr('vu', 'vagrant up')  # HashiCorp line 54
    abbr('vuv', 'vagrant up --provider=virtualbox')  # HashiCorp line 55
    abbr('vup', 'vagrant up --provider=parallels')  # HashiCorp line 56
    abbr('vuh', 'vagrant up --provider=hyperv')  # HashiCorp line 57
    abbr('vpv', 'vagrant provision')  # HashiCorp line 61
    abbr('vh', 'vagrant halt')  # HashiCorp line 62
    abbr('vhf', 'vagrant halt --force')  # HashiCorp line 63
    abbr('vrl', 'vagrant reload')  # HashiCorp line 64
    abbr('vrlp', 'vagrant reload --provision')  # HashiCorp line 65
    abbr('vsp', 'vagrant suspend')  # HashiCorp line 67
    abbr('vspg', 'vagrant suspend --all-global')  # HashiCorp line 68
    abbr('vrs', 'vagrant resume')  # HashiCorp line 69
    abbr('vd', 'vagrant destroy')  # HashiCorp line 72
    abbr('vdf', 'vagrant destroy -f')  # HashiCorp line 73
    abbr('vp', 'vagrant plugin')  # HashiCorp line 76
    abbr('vpls', 'vagrant plugin list')  # HashiCorp line 77
    abbr('vpi', 'vagrant plugin install')  # HashiCorp line 78
    abbr('vprm', 'vagrant plugin uninstall')  # HashiCorp line 79
    abbr('vpupdate', 'vagrant plugin update')  # HashiCorp line 80
    abbr('vs', 'vagrant ssh')  # HashiCorp line 83
    abbr('vsc', 'vagrant ssh-config')  # HashiCorp line 84
    abbr('vscmd', 'vagrant ssh --command')  # HashiCorp line 85
    abbr('vsn', 'vagrant snapshot')  # HashiCorp line 89
    abbr('vsnls', 'vagrant snapshot list')  # HashiCorp line 90
    abbr('vsns', 'vagrant snapshot save')  # HashiCorp line 92
    abbr('vsnr', 'vagrant snapshot restore')  # HashiCorp line 93
    abbr('vsnrm', 'vagrant snapshot delete')  # HashiCorp line 94
    abbr('vsnpu', 'vagrant snapshot push')  # HashiCorp line 96
    abbr('vsnpo', 'vagrant snapshot pop')  # HashiCorp line 97
