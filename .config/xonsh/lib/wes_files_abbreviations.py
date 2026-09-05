"""Generated from fish/load_last_interactive_only/files-specific.fish."""

from __future__ import annotations

import re
import shlex
import shutil

from wes_abbreviations import abbr
from wes_fish_bridge import fish_function


def _fish_abbreviation(function_name):
    def expand(context, _match):
        return fish_function(function_name, context.token)

    return expand


def _dot_count(token):
    dots = token.removeprefix("cd")
    return "../" * (len(dots) - 1)


def _expand_dots_command(context, _match):
    return "cd " + _dot_count(context.token)


def _expand_dots_only(context, _match):
    return _dot_count(context.token)


def _expand_zsh_equals(context, _match):
    return shutil.which(context.token.removeprefix("="))


def _ask_status(_context, _match):
    repositories = ("dotfiles", "ask-openai.nvim", "devtools.nvim")
    paths = [fish_function("__z", "--echo", repository) for repository in repositories]
    return "; ".join(f"git -C {shlex.quote(path)} status" for path in paths)


def register_files_abbreviations():
    abbr('lat', 'ls -alht')  # Fish line 2
    abbr('las', 'ls -alhS')  # Fish line 3
    abbr('la', 'ls -alh')  # Fish line 4
    abbr(re.compile('^cd\\.\\.+$'), _expand_dots_command)  # Fish line 47
    abbr(re.compile('^\\.\\.+$'), _expand_dots_only, position="anywhere")  # Fish line 49
    abbr(re.compile('^\\.\\.+$'), _expand_dots_command)  # Fish line 53
    abbr('cd-', 'cd -')  # Fish line 56
    abbr('cpr', 'cp -r')  # Fish line 59
    abbr('lns', 'ln -s')  # Fish line 60
    abbr('ask_status', _ask_status)  # Fish line 72
    abbr('touch', 'touchp')  # Fish line 136
    abbr('mkfile', 'touchp')  # Fish line 137
    abbr('mkdir', 'mkdir -p')  # Fish line 194
    abbr(re.compile('=[^\\b]+'), _expand_zsh_equals, position="anywhere")  # Fish line 219
    abbr('cdm', 'cd_dir_of_man_page')  # Fish line 240
    abbr('cdbrew', 'cd_dir_of_brew_pkg')  # Fish line 256
    abbr('cdc', 'cd_dir_of_command')  # Fish line 261
    abbr('cdd', 'cd_dir_of_path')  # Fish line 289
    abbr('cdl', 'cd_last_dir__in_current_dir')  # Fish line 291
    abbr('bath', 'bat --style=header')  # Fish line 319
    abbr('batf', 'bat --style=full')  # Fish line 320
    abbr(re.compile('(du|dust)\\d+'), _fish_abbreviation('dustX'))  # Fish line 494
    abbr('dust_HOME_2G', 'dust --number-of-lines 500 ~/ +2G')  # Fish line 500
    abbr('dust_HOMES_2G', 'dust --number-of-lines 500 /Users +2G')  # Fish line 501
    abbr('dust_ROOT_10G', 'dust --number-of-lines 500 / +10G')  # Fish line 502
    abbr('dust_HOME_recent_100M', 'dust --number-of-lines 500 --mtime -3 ~/ +100M')  # Fish line 503
    abbr('dust_HOME_old_100M', 'dust --number-of-lines 500 --mtime +90 ~/ +100M')  # Fish line 504
    abbr('-n', '--number-of-lines 500', position="anywhere", commands=('dust',))  # Fish line 508
    abbr('-M', '--mtime +7 # greater than 7 days ago', position="anywhere", commands=('dust',))  # Fish line 509
    abbr('dust_past_week', 'dust --mtime -7')  # Fish line 510
    abbr('dust_past_month', 'dust --mtime -30')  # Fish line 511
    abbr('df', 'grc df -h')  # Fish line 515
    abbr('dfm', 'grc df -h /System/Volumes/Data')  # Fish line 517
    abbr(re.compile('forr\\d*'), _fish_abbreviation('forr_abbr'))  # Fish line 526
    abbr('findd', 'find . -type d -iname "*%*"', cursor_marker="%")  # Fish line 540
    abbr('finddr', 'find . -type d -iregex ".*%.*"', cursor_marker="%")  # Fish line 541
    abbr(re.compile('tree\\d+'), _fish_abbreviation('treeX'))  # Fish line 616
    abbr(re.compile('treed\\d+'), _fish_abbreviation('treedX'))  # Fish line 621
    abbr(re.compile('treeh\\d+'), _fish_abbreviation('treehX'))  # Fish line 626
    abbr(re.compile('treeu\\d+'), _fish_abbreviation('treeuX'))  # Fish line 631
    abbr('nvim_start_server_attached', 'nvim --listen localhost:6666')  # Fish line 660
    abbr('nvim_start_server_not_attached', 'nvim --listen localhost:6666 --embed')  # Fish line 661
    abbr('nvim_client_attach_ui', 'nvim --server localhost:6666 --remote-ui')  # Fish line 663
    abbr('nvim_client_send_command', 'nvim --server localhost:6666 --remote-send')  # Fish line 664
    abbr('nvim_client_eval_expr', 'nvim --server localhost:6666 --remote-expr')  # Fish line 665
    abbr('nvim_client_open_files_in_new_tabs', 'nvim --server localhost:6666 --remote-tab')  # Fish line 666
    abbr('f', 'fish')  # Fish line 672
    abbr('x', 'xonsh')  # Fish line 673
    abbr('n', 'nvim')  # Fish line 676
    abbr('nr', _fish_abbreviation('nr_expand'))  # Fish line 677
    abbr('nd', _fish_abbreviation('nd_expand'))  # Fish line 685
    abbr('nh', _fish_abbreviation('nh_expand'))  # Fish line 693
    abbr('nn', _fish_abbreviation('nn_expand'))  # Fish line 701
    abbr('chmx', 'chmod +x')  # Fish line 952
    abbr('chmR', 'chmod -R')  # Fish line 953
