"""Processes abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import platform
import re

from wes_abbreviations import abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
    platform_abbreviation,
)


SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"

FISH_FUNCTIONS = (
    'ps_dump_env_vars_when_process_started',  # Fish line 816
    'pstreeX',  # Fish line 904
    'pstree',  # Fish line 914
    'build_abbrs_for_filetype',  # Fish line 943
    '_cat_range_abbr',  # Fish line 989
    '_flush_dns',  # Fish line 1006
    'kill_hung_grc',  # Fish line 1011
    'z',  # Fish line 1018
    '_abbr_ze',  # Fish line 1058
    'custom-kill-command-word',  # Fish line 1110
    'toggle-grc',  # Fish line 1125
    'toggle-git_commit_command',  # Fish line 1149
)


def register_processes_abbreviations():
    abbr('els', 'env | bat --language dotenv -p')  # Fish line 772
    abbr('egr', 'env | rg_grep -i ')  # Fish line 773
    abbr('envb', 'env | bat -l env')  # Fish line 774
    abbr('vls', 'set | bat --language ini -p')  # Fish line 779
    abbr('vgr', 'set | rg_grep -i ')  # Fish line 780
    abbr('agr', "_abbr_list --any '%'", cursor_marker="%")  # Fish line 783
    abbr('agrs', "_abbr_list --prefix '%'", cursor_marker="%")  # Fish line 784
    abbr('completeC', "complete -C '%'", cursor_marker="%")  # Fish line 787
    abbr('psg', 'grc ps aux | rg_grep -i ')  # Fish line 815
    abbr('enable_fish_tracing', 'set fish_trace 1')  # Fish line 837
    abbr('disable_fish_tracing', 'set --erase fish_trace')  # Fish line 838
    abbr('pgrep', 'pgrep -ilfa')  # Fish line 847
    abbr('pgrepu', 'pgrep -U $USER -ilfa')  # Fish line 851
    abbr('pkill', platform_abbreviation('pkill -9 -ilf', 'pkill -9 -if'))  # Fish line 855
    abbr('pkillu', platform_abbreviation('pkill -9 -U $USER -ilf', 'pkill -9 -U $USER -if'))  # Fish line 856
    abbr('kill9', 'kill -9')  # Fish line 876
    abbr('psfull', "grc ps -o 'user,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm' -ax")  # Fish line 878
    abbr('psf', 'grc ps f')  # Fish line 881
    abbr('pstreeg', "pstree_grep '%'", cursor_marker="%")  # Fish line 890
    abbr('pstreeg_watch', 'viddy \'fish -i -c "pstree_grep \\\'%\\\'"\'', cursor_marker="%")  # Fish line 891
    abbr(re.compile('pstree\\d+'), fish_abbreviation('pstreeX'))  # Fish line 903
    abbr('pstrees', 'pstree -s "%"', cursor_marker="%")  # Fish line 907
    abbr('pstreep', 'pstree -p')  # Fish line 908
    abbr('pstreet', 'pstree  (ps -o pid=)')  # Fish line 909
    abbr('pstreeU', 'pstree -U')  # Fish line 910
    abbr('pstreeu', 'pstree -u $(whoami)')  # Fish line 911
    abbr('pstreew', 'pstree -w')  # Fish line 912
    abbr('sed', 'gsed')  # Fish line 925
    abbr('sede', "$XONSH_SED_COMMAND -Ei 's/%//g'", cursor_marker="%")  # Fish line 930
    abbr('sedd', "$XONSH_SED_COMMAND --debug -i 's/%//g'", cursor_marker="%")  # Fish line 931
    abbr('sedi', "$XONSH_SED_COMMAND -i 's/%//g'", cursor_marker="%")  # Fish line 932
    abbr('rg', '(rg --files-with-matches %)', position="anywhere", commands=(SED_COMMAND,), cursor_marker="%")  # Fish line 940
    abbr('*nd', "--glob='!datasets'", position="anywhere", commands=('rg',))  # Fish line 980
    abbr('seda', "$XONSH_SED_COMMAND -Ei 's/%//g' (rg --files-with-matches ___) ", cursor_marker="%")  # Fish line 983
    abbr('*a', '(rg --files-with-matches ___) ', position="anywhere", commands=(SED_COMMAND,))  # Fish line 984
    abbr(re.compile('(lines|catr|catrange|sedr|sedrange)\\d+[,_-]\\d+'), fish_abbreviation('_cat_range_abbr'))  # Fish line 988
    abbr('lua_logs', "rg -g '*.lua' '^\\s*log'")  # Fish line 999
    abbr('lua_logs_commented_out', "rg -g '*.lua' '^\\s*--\\s*log'")  # Fish line 1000
    abbr('lua_prints', "rg -g '*.lua' '^\\s*print\\\\('")  # Fish line 1001
    abbr('lua_prints_commented_out', "rg -g '*.lua' '^\\s*--\\s*print\\\\('")  # Fish line 1002
    abbr('z_clean', 'z --clean')  # Fish line 1017
    abbr('ze', fish_abbreviation('_abbr_ze'), position="anywhere")  # Fish line 1057
    abbr('tf', 'terraform')  # Fish line 1079
    abbr('tfv', 'terraform validate')  # Fish line 1081
    abbr('tfi', 'terraform init')  # Fish line 1082
    abbr('tfimport', 'terraform import')  # Fish line 1083
    abbr('tff', 'terraform fmt')  # Fish line 1084
    abbr('tfa', 'terraform apply')  # Fish line 1085
    abbr('tfp', 'terraform plan')  # Fish line 1086
    abbr('tfo', 'terraform output')  # Fish line 1087
    abbr('tfshow', 'terraform show')  # Fish line 1089
    abbr('tfs', 'terraform state')  # Fish line 1091
    abbr('tfsl', 'terraform state list')  # Fish line 1092
    abbr('tfss', 'terraform state show')  # Fish line 1093
    abbr('tfsrm', 'terraform state rm')  # Fish line 1094
    abbr('tfr', 'terraform refresh')  # Fish line 1095
    abbr('tfd', 'terraform destroy')  # Fish line 1097
    abbr('tft', 'terraform taint')  # Fish line 1098
    abbr('tfu', 'terraform untaint')  # Fish line 1099
    abbr('lsofi', 'sudo lsof -i :8080%', cursor_marker="%")  # Fish line 2777
    abbr('lsof_process_for_port', 'sudo lsof -i :8080%', cursor_marker="%")  # Fish line 2778
    abbr('lsofp', 'sudo lsof -p $(pgrep -if "%" | head -1)', cursor_marker="%")  # Fish line 2782
    abbr('lsof_ports_for_process_pgrep', 'sudo lsof -p $(pgrep -if "%" | head -1)', cursor_marker="%")  # Fish line 2783
    abbr('lsofpi', 'sudo lsof -p $(pgrep -if "%" | head -1) -a -i', cursor_marker="%")  # Fish line 2784
    abbr('lsof_ports_for_pid', 'sudo lsof -p % -a -i', cursor_marker="%")  # Fish line 2785
    abbr('lsofp_watch', '$WATCH_COMMAND "sudo lsof -p \\$(pgrep -if \\"%\\" | head -1)"', cursor_marker="%")  # Fish line 2790
    abbr('ss_listening_ports', 'sudo ss -tunl')  # Fish line 2808
    abbr('ss_notlistening_ports', 'sudo ss -tun')  # Fish line 2809
    abbr('ss_all_ports', 'sudo ss -tuna')  # Fish line 2810
