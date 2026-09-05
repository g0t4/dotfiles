"""System Services abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr


FISH_FUNCTIONS = (
    'on_change_show_verbose_prompt',  # Fish line 57
    'toggle_show_verbose_prompt',  # Fish line 60
)


def register_system_services_abbreviations():
    abbr('help', 'help_online')  # Fish line 51
    abbr('lcl', 'launchctl list')  # Fish line 71
    abbr('lcp', 'launchctl print system')  # Fish line 72
    abbr('lcpu', 'launchctl print user/$(id -u)')  # Fish line 73
    abbr('lcpg', 'launchctl print gui/$(id -u)')  # Fish line 74
    abbr('lcds', 'launchctl disable system/')  # Fish line 75
    abbr('lcdu', 'launchctl disable user/$(id -u)')  # Fish line 76
    abbr('lcdg', 'launchctl disable gui/$(id -u)')  # Fish line 77
    abbr('lcstart', 'launchctl start TODO')  # Fish line 79
    abbr('lcstop', 'launchctl stop TODO')  # Fish line 80
    abbr('lcrm', 'launchctl remove TODO')  # Fish line 81
    abbr('lcexamine', 'launchctl examine TODO')  # Fish line 83
    abbr('sc', 'sudo systemctl')  # Fish line 96
    abbr('scu', 'systemctl --user')  # Fish line 98
    abbr('scudr', 'systemctl --user daemon-reload')  # Fish line 99
    abbr('scdr', 'sudo systemctl daemon-reload')  # Fish line 100
    abbr('scm', 'man systemd.index')  # Fish line 102
    abbr('scs', 'sudo systemctl status')  # Fish line 104
    abbr('scus', 'systemctl --user status')  # Fish line 105
    abbr('scstop', 'sudo systemctl stop')  # Fish line 106
    abbr('scustop', 'systemctl --user stop')  # Fish line 107
    abbr('scstart', 'sudo systemctl start')  # Fish line 108
    abbr('scustart', 'systemctl --user start')  # Fish line 109
    abbr('screstart', 'sudo systemctl restart')  # Fish line 110
    abbr('scurestart', 'systemctl --user restart')  # Fish line 111
    abbr('scenable', 'sudo systemctl enable')  # Fish line 112
    abbr('scuenable', 'systemctl --user enable')  # Fish line 113
    abbr('scdisable', 'sudo systemctl disable')  # Fish line 114
    abbr('scudisable', 'systemctl --user disable')  # Fish line 115
    abbr('sck', 'sudo systemctl kill')  # Fish line 116
    abbr('scukill', 'systemctl --user kill')  # Fish line 117
    abbr('sccat', 'sudo systemctl cat')  # Fish line 119
    abbr('scucat', 'systemctl --user cat')  # Fish line 120
    abbr('scedit', 'sudo systemctl edit')  # Fish line 121
    abbr('scuedit', 'systemctl --user edit')  # Fish line 122
    abbr('screvert', 'sudo systemctl revert')  # Fish line 123
    abbr('scurevert', 'systemctl --user revert')  # Fish line 124
    abbr('scshow', 'sudo systemctl show')  # Fish line 125
    abbr('scushow', 'systemctl --user show')  # Fish line 126
    abbr('scls', 'sudo systemctl list-units')  # Fish line 128
    abbr('sculs', 'systemctl --user list-units')  # Fish line 129
    abbr('sclsf', 'sudo systemctl list-unit-files')  # Fish line 130
    abbr('sculsf', 'systemctl --user list-unit-files')  # Fish line 131
    abbr('sclss', 'sudo systemctl list-sockets')  # Fish line 132
    abbr('sculss', 'systemctl --user list-sockets')  # Fish line 133
    abbr('sclsd', 'sudo systemctl list-dependencies')  # Fish line 134
    abbr('sculsd', 'systemctl --user list-dependencies')  # Fish line 135
    abbr('jc', 'sudo journalctl --unit')  # Fish line 138
    abbr('jcu', 'journalctl --user --unit')  # Fish line 140
    abbr('jcb', 'sudo journalctl --boot --unit')  # Fish line 142
    abbr('jcub', 'journalctl --user --boot --unit')  # Fish line 143
    abbr('jcb1', 'sudo journalctl --boot=-1 --unit')  # Fish line 144
    abbr('jcub1', 'journalctl --user --boot=-1 --unit')  # Fish line 145
    abbr('jcboots', 'sudo journalctl --list-boots')  # Fish line 146
    abbr('jcs', 'sudo journalctl --since "1min ago" --unit')  # Fish line 148
    abbr('jcus', 'journactl --user --since "1min ago" --unit')  # Fish line 149
    abbr('jck', 'sudo journalctl -k')  # Fish line 150
    abbr('jcuk', 'journalctl --user -k')  # Fish line 151
    abbr('jcf', 'sudo journalctl --follow --unit')  # Fish line 153
    abbr('jcuf', 'journalctl --user --follow --unit')  # Fish line 154
    abbr('jcfa', 'sudo journalctl --follow --no-tail --unit')  # Fish line 155
    abbr('jcufa', 'journalctl --user --follow --no-tail --unit')  # Fish line 156
    abbr('jc_rotate_vaccum', 'sudo journalctl --rotate --vacuum-time=1s')  # Fish line 162
    abbr('jc_nuke', 'sudo journalctl --rotate --vacuum-time=1s')  # Fish line 163
    abbr('jc_rotate_only', 'sudo journalctl --rotate')  # Fish line 165
    abbr('jcvs', 'sudo journalctl --vacuum-size=100M')  # Fish line 166
    abbr('jcdu', 'sudo journalctl --disk-usage')  # Fish line 168
    abbr('jcud', 'journalctl --user --disk-usage')  # Fish line 169
    abbr('ctr', 'sudo ctr')  # Fish line 175
    abbr('ctrn', 'sudo ctr namespaces ls')  # Fish line 176
    abbr('ctrc', 'sudo ctr container ls')  # Fish line 179
    abbr('ctrci', 'sudo ctr container info')  # Fish line 180
    abbr('ctrcrm', 'sudo ctr container rm')  # Fish line 181
    abbr('ctri', 'sudo ctr image ls')  # Fish line 184
    abbr('ctripull', 'sudo ctr image pull docker.io/library/%', cursor_marker="%")  # Fish line 185
    abbr('ctrirm', 'sudo ctr image rm docker.io/library/%', cursor_marker="%")  # Fish line 186
    abbr('ctrtls', 'sudo ctr task ls')  # Fish line 189
    abbr('ctrtps', 'sudo ctr task ps')  # Fish line 190
    abbr('ctrta', 'sudo ctr task attach')  # Fish line 191
    abbr('ctrtrm', 'sudo ctr task rm')  # Fish line 192
    abbr('ctrtk', 'sudo ctr task kill --all')  # Fish line 193
    abbr('ctrtks', 'sudo ctr task kill --all --signal=SIGKILL')  # Fish line 194
    abbr('ctrtpause', 'sudo ctr task pause')  # Fish line 195
    abbr('ctrtresume', 'sudo ctr task resume')  # Fish line 196
    abbr('ctrtstart', 'sudo ctr task start')  # Fish line 197
    abbr('ctrtexec', 'sudo ctr task exec --tty --exec-id 100 ')  # Fish line 198
    abbr('ctrr', 'sudo ctr run -t --rm')  # Fish line 201
    abbr('ctrrnd', 'sudo ctr run -d docker.io/library/nginx:latest web')  # Fish line 203
    abbr('ctrrn', 'sudo ctr run -t --rm --net-host docker.io/library/nginx:latest web')  # Fish line 204
    abbr('containerdc', 'containerd config dump | bat -l toml')  # Fish line 212
    abbr('containerdcdefault', 'containerd config default | bat -l toml')  # Fish line 213
