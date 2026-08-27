"""Generated from zsh/compat_fish/hashicorp.zsh."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr


def register_hashicorp_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'pa', 'packer')  # HashiCorp line 3
    abbr(registry, 'pai', 'packer init .')  # HashiCorp line 4
    abbr(registry, 'pav', 'packer validate .')  # HashiCorp line 5
    abbr(registry, 'paf', 'packer fmt .')  # HashiCorp line 6
    abbr(registry, 'pab', 'packer build .')  # HashiCorp line 7
    abbr(registry, 'v', 'vagrant')  # HashiCorp line 22
    abbr(registry, 'vlsc', 'vagrant list-commands')  # HashiCorp line 23
    abbr(registry, 'vi', 'vagrant init --minimal')  # HashiCorp line 26
    abbr(registry, 'vv', 'vagrant validate')  # HashiCorp line 27
    abbr(registry, 'vc', 'vagrant cloud')  # HashiCorp line 30
    abbr(registry, 'vcs', 'vagrant cloud search')  # HashiCorp line 31
    abbr(registry, 'vcb', 'vagrant cloud box show')  # HashiCorp line 32
    abbr(registry, 'vb', 'vagrant box')  # HashiCorp line 35
    abbr(registry, 'vbls', 'vagrant box list -i')  # HashiCorp line 36
    abbr(registry, 'vba', 'vagrant box add')  # HashiCorp line 37
    abbr(registry, 'vbo', 'vagrant box outdated')  # HashiCorp line 38
    abbr(registry, 'vbog', 'vagrant box outdated --global')  # HashiCorp line 39
    abbr(registry, 'vbu', 'vagrant box update')  # HashiCorp line 40
    abbr(registry, 'vbub', 'vagrant box update --box')  # HashiCorp line 41
    abbr(registry, 'vbpr', 'vagrant box prune --dry-run')  # HashiCorp line 42
    abbr(registry, 'vbrm', 'vagrant box remove')  # HashiCorp line 43
    abbr(registry, 'vbrep', 'vagrant box repackage')  # HashiCorp line 44
    abbr(registry, 'vpack', 'vagrant package --base ')  # HashiCorp line 47
    abbr(registry, 'vst', 'vagrant status')  # HashiCorp line 50
    abbr(registry, 'vgst', 'vagrant global-status --prune')  # HashiCorp line 51
    abbr(registry, 'vu', 'vagrant up')  # HashiCorp line 54
    abbr(registry, 'vuv', 'vagrant up --provider=virtualbox')  # HashiCorp line 55
    abbr(registry, 'vup', 'vagrant up --provider=parallels')  # HashiCorp line 56
    abbr(registry, 'vuh', 'vagrant up --provider=hyperv')  # HashiCorp line 57
    abbr(registry, 'vpv', 'vagrant provision')  # HashiCorp line 61
    abbr(registry, 'vh', 'vagrant halt')  # HashiCorp line 62
    abbr(registry, 'vhf', 'vagrant halt --force')  # HashiCorp line 63
    abbr(registry, 'vrl', 'vagrant reload')  # HashiCorp line 64
    abbr(registry, 'vrlp', 'vagrant reload --provision')  # HashiCorp line 65
    abbr(registry, 'vsp', 'vagrant suspend')  # HashiCorp line 67
    abbr(registry, 'vspg', 'vagrant suspend --all-global')  # HashiCorp line 68
    abbr(registry, 'vrs', 'vagrant resume')  # HashiCorp line 69
    abbr(registry, 'vd', 'vagrant destroy')  # HashiCorp line 72
    abbr(registry, 'vdf', 'vagrant destroy -f')  # HashiCorp line 73
    abbr(registry, 'vp', 'vagrant plugin')  # HashiCorp line 76
    abbr(registry, 'vpls', 'vagrant plugin list')  # HashiCorp line 77
    abbr(registry, 'vpi', 'vagrant plugin install')  # HashiCorp line 78
    abbr(registry, 'vprm', 'vagrant plugin uninstall')  # HashiCorp line 79
    abbr(registry, 'vpupdate', 'vagrant plugin update')  # HashiCorp line 80
    abbr(registry, 'vs', 'vagrant ssh')  # HashiCorp line 83
    abbr(registry, 'vsc', 'vagrant ssh-config')  # HashiCorp line 84
    abbr(registry, 'vscmd', 'vagrant ssh --command')  # HashiCorp line 85
    abbr(registry, 'vsn', 'vagrant snapshot')  # HashiCorp line 89
    abbr(registry, 'vsnls', 'vagrant snapshot list')  # HashiCorp line 90
    abbr(registry, 'vsns', 'vagrant snapshot save')  # HashiCorp line 92
    abbr(registry, 'vsnr', 'vagrant snapshot restore')  # HashiCorp line 93
    abbr(registry, 'vsnrm', 'vagrant snapshot delete')  # HashiCorp line 94
    abbr(registry, 'vsnpu', 'vagrant snapshot push')  # HashiCorp line 96
    abbr(registry, 'vsnpo', 'vagrant snapshot pop')  # HashiCorp line 97
