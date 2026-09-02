"""System Services abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr


FISH_FUNCTIONS = (
    'on_change_show_verbose_prompt',  # Fish line 57
    'toggle_show_verbose_prompt',  # Fish line 60
)


def register_system_services_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'help', 'help_online')  # Fish line 51
    abbr(registry, 'lcl', 'launchctl list')  # Fish line 71
    abbr(registry, 'lcp', 'launchctl print system')  # Fish line 72
    abbr(registry, 'lcpu', 'launchctl print user/$(id -u)')  # Fish line 73
    abbr(registry, 'lcpg', 'launchctl print gui/$(id -u)')  # Fish line 74
    abbr(registry, 'lcds', 'launchctl disable system/')  # Fish line 75
    abbr(registry, 'lcdu', 'launchctl disable user/$(id -u)')  # Fish line 76
    abbr(registry, 'lcdg', 'launchctl disable gui/$(id -u)')  # Fish line 77
    abbr(registry, 'lcstart', 'launchctl start TODO')  # Fish line 79
    abbr(registry, 'lcstop', 'launchctl stop TODO')  # Fish line 80
    abbr(registry, 'lcrm', 'launchctl remove TODO')  # Fish line 81
    abbr(registry, 'lcexamine', 'launchctl examine TODO')  # Fish line 83
    abbr(registry, 'sc', 'sudo systemctl')  # Fish line 96
    abbr(registry, 'scu', 'systemctl --user')  # Fish line 98
    abbr(registry, 'scudr', 'systemctl --user daemon-reload')  # Fish line 99
    abbr(registry, 'scdr', 'sudo systemctl daemon-reload')  # Fish line 100
    abbr(registry, 'scm', 'man systemd.index')  # Fish line 102
    abbr(registry, 'scs', 'sudo systemctl status')  # Fish line 104
    abbr(registry, 'scus', 'systemctl --user status')  # Fish line 105
    abbr(registry, 'scstop', 'sudo systemctl stop')  # Fish line 106
    abbr(registry, 'scustop', 'systemctl --user stop')  # Fish line 107
    abbr(registry, 'scstart', 'sudo systemctl start')  # Fish line 108
    abbr(registry, 'scustart', 'systemctl --user start')  # Fish line 109
    abbr(registry, 'screstart', 'sudo systemctl restart')  # Fish line 110
    abbr(registry, 'scurestart', 'systemctl --user restart')  # Fish line 111
    abbr(registry, 'scenable', 'sudo systemctl enable')  # Fish line 112
    abbr(registry, 'scuenable', 'systemctl --user enable')  # Fish line 113
    abbr(registry, 'scdisable', 'sudo systemctl disable')  # Fish line 114
    abbr(registry, 'scudisable', 'systemctl --user disable')  # Fish line 115
    abbr(registry, 'sck', 'sudo systemctl kill')  # Fish line 116
    abbr(registry, 'scukill', 'systemctl --user kill')  # Fish line 117
    abbr(registry, 'sccat', 'sudo systemctl cat')  # Fish line 119
    abbr(registry, 'scucat', 'systemctl --user cat')  # Fish line 120
    abbr(registry, 'scedit', 'sudo systemctl edit')  # Fish line 121
    abbr(registry, 'scuedit', 'systemctl --user edit')  # Fish line 122
    abbr(registry, 'screvert', 'sudo systemctl revert')  # Fish line 123
    abbr(registry, 'scurevert', 'systemctl --user revert')  # Fish line 124
    abbr(registry, 'scshow', 'sudo systemctl show')  # Fish line 125
    abbr(registry, 'scushow', 'systemctl --user show')  # Fish line 126
    abbr(registry, 'scls', 'sudo systemctl list-units')  # Fish line 128
    abbr(registry, 'sculs', 'systemctl --user list-units')  # Fish line 129
    abbr(registry, 'sclsf', 'sudo systemctl list-unit-files')  # Fish line 130
    abbr(registry, 'sculsf', 'systemctl --user list-unit-files')  # Fish line 131
    abbr(registry, 'sclss', 'sudo systemctl list-sockets')  # Fish line 132
    abbr(registry, 'sculss', 'systemctl --user list-sockets')  # Fish line 133
    abbr(registry, 'sclsd', 'sudo systemctl list-dependencies')  # Fish line 134
    abbr(registry, 'sculsd', 'systemctl --user list-dependencies')  # Fish line 135
    abbr(registry, 'jc', 'sudo journalctl --unit')  # Fish line 138
    abbr(registry, 'jcu', 'journalctl --user --unit')  # Fish line 140
    abbr(registry, 'jcb', 'sudo journalctl --boot --unit')  # Fish line 142
    abbr(registry, 'jcub', 'journalctl --user --boot --unit')  # Fish line 143
    abbr(registry, 'jcb1', 'sudo journalctl --boot=-1 --unit')  # Fish line 144
    abbr(registry, 'jcub1', 'journalctl --user --boot=-1 --unit')  # Fish line 145
    abbr(registry, 'jcboots', 'sudo journalctl --list-boots')  # Fish line 146
    abbr(registry, 'jcs', 'sudo journalctl --since "1min ago" --unit')  # Fish line 148
    abbr(registry, 'jcus', 'journactl --user --since "1min ago" --unit')  # Fish line 149
    abbr(registry, 'jck', 'sudo journalctl -k')  # Fish line 150
    abbr(registry, 'jcuk', 'journalctl --user -k')  # Fish line 151
    abbr(registry, 'jcf', 'sudo journalctl --follow --unit')  # Fish line 153
    abbr(registry, 'jcuf', 'journalctl --user --follow --unit')  # Fish line 154
    abbr(registry, 'jcfa', 'sudo journalctl --follow --no-tail --unit')  # Fish line 155
    abbr(registry, 'jcufa', 'journalctl --user --follow --no-tail --unit')  # Fish line 156
    abbr(registry, 'jc_rotate_vaccum', 'sudo journalctl --rotate --vacuum-time=1s')  # Fish line 162
    abbr(registry, 'jc_nuke', 'sudo journalctl --rotate --vacuum-time=1s')  # Fish line 163
    abbr(registry, 'jc_rotate_only', 'sudo journalctl --rotate')  # Fish line 165
    abbr(registry, 'jcvs', 'sudo journalctl --vacuum-size=100M')  # Fish line 166
    abbr(registry, 'jcdu', 'sudo journalctl --disk-usage')  # Fish line 168
    abbr(registry, 'jcud', 'journalctl --user --disk-usage')  # Fish line 169
    abbr(registry, 'ctr', 'sudo ctr')  # Fish line 175
    abbr(registry, 'ctrn', 'sudo ctr namespaces ls')  # Fish line 176
    abbr(registry, 'ctrc', 'sudo ctr container ls')  # Fish line 179
    abbr(registry, 'ctrci', 'sudo ctr container info')  # Fish line 180
    abbr(registry, 'ctrcrm', 'sudo ctr container rm')  # Fish line 181
    abbr(registry, 'ctri', 'sudo ctr image ls')  # Fish line 184
    abbr(registry, 'ctripull', 'sudo ctr image pull docker.io/library/%', cursor_marker="%")  # Fish line 185
    abbr(registry, 'ctrirm', 'sudo ctr image rm docker.io/library/%', cursor_marker="%")  # Fish line 186
    abbr(registry, 'ctrtls', 'sudo ctr task ls')  # Fish line 189
    abbr(registry, 'ctrtps', 'sudo ctr task ps')  # Fish line 190
    abbr(registry, 'ctrta', 'sudo ctr task attach')  # Fish line 191
    abbr(registry, 'ctrtrm', 'sudo ctr task rm')  # Fish line 192
    abbr(registry, 'ctrtk', 'sudo ctr task kill --all')  # Fish line 193
    abbr(registry, 'ctrtks', 'sudo ctr task kill --all --signal=SIGKILL')  # Fish line 194
    abbr(registry, 'ctrtpause', 'sudo ctr task pause')  # Fish line 195
    abbr(registry, 'ctrtresume', 'sudo ctr task resume')  # Fish line 196
    abbr(registry, 'ctrtstart', 'sudo ctr task start')  # Fish line 197
    abbr(registry, 'ctrtexec', 'sudo ctr task exec --tty --exec-id 100 ')  # Fish line 198
    abbr(registry, 'ctrr', 'sudo ctr run -t --rm')  # Fish line 201
    abbr(registry, 'ctrrnd', 'sudo ctr run -d docker.io/library/nginx:latest web')  # Fish line 203
    abbr(registry, 'ctrrn', 'sudo ctr run -t --rm --net-host docker.io/library/nginx:latest web')  # Fish line 204
    abbr(registry, 'containerdc', 'containerd config dump | bat -l toml')  # Fish line 212
    abbr(registry, 'containerdcdefault', 'containerd config default | bat -l toml')  # Fish line 213
