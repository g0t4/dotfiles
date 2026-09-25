"""generated from Fish"""

from __future__ import annotations

import re
import platform

from xonsh.built_ins import XSH
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)

SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"

FISH_FUNCTIONS = (
    'ps_dump_env_vars_when_process_started',
    'pstreeX',
    'pstree',
    'build_abbrs_for_filetype',
    '_cat_range_abbr',
    '_flush_dns',
    'kill_hung_grc',
    'z',
    '_abbr_ze',
    'custom-kill-command-word',
    'toggle-grc',
    'toggle-git_commit_command',
)


def register_wes_processes_abbreviations():
    wrap_fish_functions(XSH.aliases, FISH_FUNCTIONS)
    abbr('els', 'env | bat --language dotenv -p')
    abbr('egr', 'env | rg_grep -i ')
    abbr('envb', 'env | bat -l env')
    abbr('vls', 'set | bat --language ini -p')
    abbr('vgr', 'set | rg_grep -i ')
    abbr('agr', "_abbr_list --any '%'", cursor_marker="%")
    abbr('agrs', "_abbr_list --prefix '%'", cursor_marker="%")
    abbr('completeC', "complete -C '%'", cursor_marker="%")
    abbr('pid', '@(os.getpid())', position="anywhere")
    abbr('psg', 'grc ps aux | rg_grep -i ')
    abbr('enable_fish_tracing', 'set fish_trace 1')
    abbr('disable_fish_tracing', 'set --erase fish_trace')
    abbr('pgrep', 'pgrep -ilfa')
    abbr('pgrepu', 'pgrep -U $USER -ilfa')
    abbr('pkill', platform_abbreviation('pkill -9 -ilf', 'pkill -9 -if'))
    abbr('pkillu', platform_abbreviation('pkill -9 -U $USER -ilf', 'pkill -9 -U $USER -if'))
    abbr('kill9', 'kill -9')
    abbr('psfull', "grc ps -o 'user,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm' -ax")
    abbr('psf', 'grc ps f')
    abbr('pstreeg', "pstree_grep '%'", cursor_marker="%")
    abbr('pstreeg_watch', 'viddy \'fish -i -c "pstree_grep \\\'%\\\'"\'', cursor_marker="%")
    abbr(re.compile('pstree\\d+'), abbr_from_fish_function('pstreeX'))
    abbr('pstrees', 'pstree -s "%"', cursor_marker="%")
    abbr('pstreep', 'pstree -p')
    abbr('pstreet', 'pstree  (ps -o pid=)')
    abbr('pstreeU', 'pstree -U')
    abbr('pstreeu', 'pstree -u $(whoami)')
    abbr('pstreew', 'pstree -w')
    abbr('sed', 'gsed')
    abbr('sede', "$XONSH_SED_COMMAND -Ei 's/%//g'", cursor_marker="%")
    abbr('sedd', "$XONSH_SED_COMMAND --debug -i 's/%//g'", cursor_marker="%")
    abbr('sedi', "$XONSH_SED_COMMAND -i 's/%//g'", cursor_marker="%")
    abbr('rg', '(rg --files-with-matches %)', position="anywhere", commands=(SED_COMMAND,), cursor_marker="%")
    abbr('*nd', "--glob '!datasets'", position="anywhere", commands=('rg',))
    abbr('seda', "$XONSH_SED_COMMAND -Ei 's/%//g' (rg --files-with-matches ___) ", cursor_marker="%")
    abbr('*a', '(rg --files-with-matches ___) ', position="anywhere", commands=(SED_COMMAND,))
    abbr(re.compile('(lines|catr|catrange|sedr|sedrange)\\d+[,_-]\\d+'), abbr_from_fish_function('_cat_range_abbr'))
    abbr('lua_logs', "rg -g '*.lua' '^\\s*log'")
    abbr('lua_logs_commented_out', "rg -g '*.lua' '^\\s*--\\s*log'")
    abbr('lua_prints', "rg -g '*.lua' '^\\s*print\\\\('")
    abbr('lua_prints_commented_out', "rg -g '*.lua' '^\\s*--\\s*print\\\\('")
    abbr('z_clean', 'z --clean')
    abbr('ze', abbr_from_fish_function('_abbr_ze'), position="anywhere")
    abbr('tf', 'terraform')
    abbr('tfv', 'terraform validate')
    abbr('tfi', 'terraform init')
    abbr('tfimport', 'terraform import')
    abbr('tff', 'terraform fmt')
    abbr('tfa', 'terraform apply')
    abbr('tfp', 'terraform plan')
    abbr('tfo', 'terraform output')
    abbr('tfshow', 'terraform show')
    abbr('tfs', 'terraform state')
    abbr('tfsl', 'terraform state list')
    abbr('tfss', 'terraform state show')
    abbr('tfsrm', 'terraform state rm')
    abbr('tfr', 'terraform refresh')
    abbr('tfd', 'terraform destroy')
    abbr('tft', 'terraform taint')
    abbr('tfu', 'terraform untaint')
    abbr('lsofi', 'sudo lsof -i :8080%', cursor_marker="%")
    abbr('lsof_process_for_port', 'sudo lsof -i :8080%', cursor_marker="%")
    abbr('lsofp', 'sudo lsof -p $(pgrep -if "%" | head -1)', cursor_marker="%")
    abbr('lsof_ports_for_process_pgrep', 'sudo lsof -p $(pgrep -if "%" | head -1)', cursor_marker="%")
    abbr('lsofpi', 'sudo lsof -p $(pgrep -if "%" | head -1) -a -i', cursor_marker="%")
    abbr('lsof_ports_for_pid', 'sudo lsof -p % -a -i', cursor_marker="%")
    abbr('lsofp_watch', '$WATCH_COMMAND "sudo lsof -p \\$(pgrep -if \\"%\\" | head -1)"', cursor_marker="%")
    abbr('ss_listening_ports', 'sudo ss -tunl')
    abbr('ss_notlistening_ports', 'sudo ss -tun')
    abbr('ss_all_ports', 'sudo ss -tuna')
