"""Generated from fish/load_last_interactive_only/files-specific.fish."""

from __future__ import annotations

import re
import shlex
import shutil

from wes_abbreviations import abbr
from wes_fish_bridge import fish_function
from wes_fish_migration import abbr_from_fish_function


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
    abbr('lat', 'ls -alht')
    abbr('las', 'ls -alhS')
    abbr('la', 'ls -alh')
    abbr(re.compile('^cd\\.\\.+$'), _expand_dots_command)
    abbr(re.compile('^\\.\\.+$'), _expand_dots_only, position="anywhere")
    abbr(re.compile('^\\.\\.+$'), _expand_dots_command)
    abbr('cd-', 'cd -')
    abbr('cpr', 'cp -r')
    abbr('lns', 'ln -s')
    abbr('ask_status', _ask_status)
    abbr('touch', 'touchp')
    abbr('mkfile', 'touchp')
    abbr('mkdir', 'mkdir -p')
    abbr(re.compile('=[^\\b]+'), _expand_zsh_equals, position="anywhere")
    abbr('cdm', 'cd_dir_of_man_page')
    abbr('cdbrew', 'cd_dir_of_brew_pkg')
    abbr('cdc', 'cd_dir_of_command')
    abbr('cdd', 'cd_dir_of_path')
    abbr('cdl', 'cd_last_dir__in_current_dir')
    abbr('batll', 'bat --list-languages')
    abbr('bath', 'bat --style=header')
    abbr('batf', 'bat --style=full')
    abbr(re.compile('(du|dust)\\d+'), abbr_from_fish_function('dustX'))
    abbr('dust_HOME_2G', 'dust --number-of-lines 500 ~/ +2G')
    abbr('dust_HOMES_2G', 'dust --number-of-lines 500 /Users +2G')
    abbr('dust_ROOT_10G', 'dust --number-of-lines 500 / +10G')
    abbr('dust_HOME_recent_100M', 'dust --number-of-lines 500 --mtime -3 ~/ +100M')
    abbr('dust_HOME_old_100M', 'dust --number-of-lines 500 --mtime +90 ~/ +100M')
    abbr('-n', '--number-of-lines 500', position="anywhere", commands=('dust',))
    abbr('-M', '--mtime +7 # greater than 7 days ago', position="anywhere", commands=('dust',))
    abbr('dust_past_week', 'dust --mtime -7')
    abbr('dust_past_month', 'dust --mtime -30')
    abbr('df', 'grc df -h')
    abbr('dfm', 'grc df -h /System/Volumes/Data')
    abbr(re.compile('forr\\d*'), abbr_from_fish_function('forr_abbr'))
    abbr('findd', 'find . -type d -iname "*%*"', cursor_marker="%")
    abbr('finddr', 'find . -type d -iregex ".*%.*"', cursor_marker="%")
    abbr(re.compile('tree\\d+'), abbr_from_fish_function('treeX'))
    abbr(re.compile('treed\\d+'), abbr_from_fish_function('treedX'))
    abbr(re.compile('treeh\\d+'), abbr_from_fish_function('treehX'))
    abbr(re.compile('treeu\\d+'), abbr_from_fish_function('treeuX'))
    abbr('nvim_start_server_attached', 'nvim --listen localhost:6666')
    abbr('nvim_start_server_not_attached', 'nvim --listen localhost:6666 --embed')
    abbr('nvim_client_attach_ui', 'nvim --server localhost:6666 --remote-ui')
    abbr('nvim_client_send_command', 'nvim --server localhost:6666 --remote-send')
    abbr('nvim_client_eval_expr', 'nvim --server localhost:6666 --remote-expr')
    abbr('nvim_client_open_files_in_new_tabs', 'nvim --server localhost:6666 --remote-tab')
    abbr('f', 'fish')
    abbr('x', 'xonsh')
    abbr('n', 'nvim')
    abbr('nr', abbr_from_fish_function('nr_expand'))
    abbr('nd', abbr_from_fish_function('nd_expand'))
    abbr('nh', abbr_from_fish_function('nh_expand'))
    abbr('nn', abbr_from_fish_function('nn_expand'))
    abbr('chmx', 'chmod +x')
    abbr('chmR', 'chmod -R')
