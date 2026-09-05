"""Generated from Fish's files-search-specific abbreviation inventory."""

from __future__ import annotations

import platform
import re

from wes_abbreviations import AbbreviationResult, abbr
from wes_fish_bridge import UnsupportedFishFunctionError, fish_function


FIND_COMMAND = "gfind" if platform.system() == "Darwin" else "find"


def _fish_abbreviation(function_name):
    def expand(context, _match):
        return fish_function(function_name, context.token)

    return expand


def _unsupported_abbreviation(function_name, reason):
    def expand(_context, _match):
        raise UnsupportedFishFunctionError(
            f"{function_name}: TODO SKIPPED_MIGRATION: {reason}"
        )

    return expand


def _expand_fd_depth(context, _match):
    return f"fd --max-depth={context.token.removeprefix('fd')}"


def _expand_rgu(context, _match):
    after_cursor = context.buffer[context.cursor :].strip()
    if after_cursor and not after_cursor.startswith("-"):
        return "rg -u"
    return AbbreviationResult('rg -u ""', cursor=len('rg -u "'))


def register_files_search_abbreviations():
    abbr('mdfind_killall', 'killall mds mds_stores mds_worker Spotlight')
    abbr('killall_spotlight', 'killall mds mds_stores mds_worker Spotlight')
    abbr('mdfind_name', 'mdfind \'kMDItemFSName == "*%*"c\'', cursor_marker="%")
    abbr('mdfind_path', 'mdfind \'kMDItemFSPath == "*%*"c\'', cursor_marker="%")
    abbr('mdfind_dir', 'mdfind \'kMDItemContentType == "public.folder" && kMDItemFSName == "*%*"c\'', cursor_marker="%")
    abbr('mdfind_live', 'mdfind -live \'kMDItemFSName == "*%*"c\'', cursor_marker="%")
    abbr('mdfind_-name', "mdfind -name '%'", cursor_marker="%")
    abbr('mdfind_contents', 'mdfind \'kMDItemTextContent == "*%*"c\'', cursor_marker="%")
    abbr('mdfind_interpret_spotlight', "mdfind -interpret '%'", cursor_marker="%")
    abbr('mdfind_today', "mdfind date:today '%'", cursor_marker="%")
    abbr('mdfind_yesterday', "mdfind date:yesterday '%'", cursor_marker="%")
    abbr('mdfind_this_week', "mdfind 'date:this week' '%'", cursor_marker="%")
    abbr('mdfind_this_month', "mdfind 'date:this month' '%'", cursor_marker="%")
    abbr('mdfind_this_year', "mdfind 'date:this year' '%'", cursor_marker="%")
    abbr('mdfind_example_images_yesterday', 'mdfind "kind:image date:yesterday"')
    abbr('mdfind_example_installed_apps', 'mdfind kMDItemAppStoreHasReceipt=1')
    abbr('mdfind_example_tagged_green', 'mdfind "kMDItemUserTags = Green"')
    abbr('mdfind_example_tagged_red', 'mdfind "kMDItemUserTags = Red"')
    abbr('mdfind_example_tagged_yellow', 'mdfind "kMDItemUserTags = Yellow"')
    abbr('mdfind_example_tagged_blue', 'mdfind "kMDItemUserTags = Blue"')
    abbr('mdfind_example_count_readmes', 'mdfind -name readme.txt -count')
    abbr('mdfind_example_homdir_last3days', "mdfind -onlyin ~ 'kMDItemFSContentChangeDate >= $time.today(-3)'")
    abbr('mdfind_example_onlyin_PWD', 'mdfind -onlyin . -name pyproject.toml')
    abbr('mdfind_example_images_keywords', 'mdfind "kind:images curl"')
    abbr('mdfind_kind_app', "mdfind kind:app '%'", cursor_marker="%")
    abbr('mdfind_kind_preferences', 'mdfind "kind:preferences"')
    abbr('mdfind_kind_folder', 'mdfind "kind:folder"')
    abbr('mdfind_kind_image', 'mdfind "kind:image"')
    abbr('mdfind_kind_movie', 'mdfind "kind:movie"')
    abbr('mdfind_kind_pdf', 'mdfind "kind:pdf"')
    abbr('mdfind_kind_', 'mdfind "kind:%"', cursor_marker="%")
    abbr('mdfind_kind_contact', 'kind:contact')
    abbr('mdimport_list_attrs', "mdimport -A | rg_grep -i '%'", cursor_marker="%")
    abbr('mdimport_list_importers', "mdimport -L | rg_grep -i '%'", cursor_marker="%")
    abbr('mdimport_dump_schema', "mdimport -X | rg_grep -i '%'", cursor_marker="%")
    abbr('mdls_item_attrs', "mdls -plist - '%' | bat -l xml", cursor_marker="%")
    abbr('md_diagnose', 'sudo mddiagnose')
    abbr('mdo', _unsupported_abbreviation('md_open', 'changes directory from an interactive fzf picker'))
    abbr('mdcd', _unsupported_abbreviation('mdfind_cd_dir', 'changes directory from an interactive fzf picker'))
    abbr('find', FIND_COMMAND)
    abbr('finde', f"{FIND_COMMAND} . -executable")
    abbr('findud', f"{FIND_COMMAND} '%' -user wesdemos", cursor_marker="%")
    abbr('finduw', f"{FIND_COMMAND} '%' -user wes", cursor_marker="%")
    abbr('g=w', '-not -perm -g=w', position="anywhere", commands=(FIND_COMMAND,))
    abbr('o=w', '-not -perm -o=w', position="anywhere", commands=(FIND_COMMAND,))
    abbr('fdnh', 'fd --no-hidden')
    abbr('fdu', 'fd --unrestricted')
    abbr('fd_nonegregious', 'fd --unrestricted --exclude .venv --exclude __pycache__ --exclude .rag --exclude .git --exclude node_modules | sort -h')
    abbr('fd_nonegregious_diff', "diff_two_commands 'fd --unrestricted --exclude .venv --exclude __pycache__ --exclude .rag --exclude .git --exclude node_modules | sort -h' 'fd | sort -h'")
    abbr('fdi', 'fd --ignore-case')
    abbr('fdF', 'fd --fixed-strings')
    abbr('fd_ext', 'fd --extension')
    abbr('fdE', 'fd --exclude')
    abbr('and', '--and', position="anywhere", commands=('fd',))
    abbr('fdh', 'fd --help')
    abbr('-0', '--print0', position="anywhere", commands=('fd',))
    abbr('-a', '--absolute-path', position="anywhere", commands=('fd',))
    abbr('-C', '--base-directory', position="anywhere", commands=('fd',))
    abbr('-c', '--color', position="anywhere", commands=('fd',))
    abbr('-d', '--max-depth', position="anywhere", commands=('fd',))
    abbr('-E', '--exclude', position="anywhere", commands=('fd',))
    abbr('-e', '--extension', position="anywhere", commands=('fd',))
    abbr('-F', '--fixed-strings', position="anywhere", commands=('fd',))
    abbr('-F', '--fixed-strings', position="anywhere", commands=('fd',))
    abbr('-g', '--glob', position="anywhere", commands=('fd',))
    abbr('-h', '--help', position="anywhere", commands=('fd',))
    abbr('-H', '--hidden', position="anywhere", commands=('fd',))
    abbr('-i', '--ignore-case', position="anywhere", commands=('fd',))
    abbr('-I', '--no-ignore', position="anywhere", commands=('fd',))
    abbr('-j', '--threads', position="anywhere", commands=('fd',))
    abbr('-L', '--follow', position="anywhere", commands=('fd',))
    abbr('-l', '--list-details', position="anywhere", commands=('fd',))
    abbr('-o', '--owner', position="anywhere", commands=('fd',))
    abbr('-p', '--full-path', position="anywhere", commands=('fd',))
    abbr('-q', '--quiet', position="anywhere", commands=('fd',))
    abbr('-s', '--case-sensitive', position="anywhere", commands=('fd',))
    abbr('-S', '--size', position="anywhere", commands=('fd',))
    abbr('-t', '--type', position="anywhere", commands=('fd',))
    abbr('-u', '--unrestricted', position="anywhere", commands=('fd',))
    abbr('-V', '--version', position="anywhere", commands=('fd',))
    abbr('-x', '--exec', position="anywhere", commands=('fd',))
    abbr('-X', '--exec-batch', position="anywhere", commands=('fd',))
    abbr('fdabs', 'fd --absolute-path')
    abbr('fdl', 'fd --list-details')
    abbr('fdfp', 'fd --full-path')
    abbr(re.compile('fd\\d+'), _expand_fd_depth)
    abbr('fd_changed_within', 'fd --changed-within "%"', cursor_marker="%")
    abbr('fd_changed_within_hours', 'fd --changed-within "% h"', cursor_marker="%")
    abbr('fd_changed_within_days', 'fd --changed-within "% d"', cursor_marker="%")
    abbr('fd_changed_within_weeks', 'fd --changed-within "% weeks"', cursor_marker="%")
    abbr('fd_changed_within_months', 'fd --changed-within "% months"', cursor_marker="%")
    abbr('fd_changed_within_years', 'fd --changed-within "% years"', cursor_marker="%")
    abbr('fd_changed_before', 'fd --changed-before "%"', cursor_marker="%")
    abbr('fdx', 'fd --exec')
    abbr('fdxb', 'fd --exec-batch')
    abbr('fdq', 'fd --quiet')
    abbr('-F', '--fixed-strings', position="anywhere", commands=('fd',))
    abbr('fdtb', 'fd --type block-device')
    abbr('fdtc', 'fd --type char-device')
    abbr('fdtd', 'fd --type dir')
    abbr('fdte', 'fd --type empty')
    abbr('fdtf', 'fd --type file')
    abbr('fdtl', 'fd --type symlink')
    abbr('fdtp', 'fd --type pipe')
    abbr('fdts', 'fd --type socket')
    abbr('fdtx', 'fd --type executable')
    abbr('list_filetype_extensions', "fd --type file | awk -F. 'NF > 1 {print $NF}' | sort | uniq -c | sort")
    abbr('fd_extensionless_files', 'fd "^[^\\.]+\\$" --type file')
    abbr('rgc', 'rg --case-sensitive "%"', cursor_marker="%")
    abbr('rgi', 'rg -i "%"', cursor_marker="%")
    abbr('rgh', 'rg --hidden "%"', cursor_marker="%")
    abbr('grep', 'rg_grep "%"', cursor_marker="%")
    abbr('h', 'history show all | bat -l xonsh --color always | less -F')
    abbr('hgr', 'history show all | rg_grep "%"', cursor_marker="%")
    abbr('hm', 'history pull')
    abbr('hd', 'history delete "%"', cursor_marker="%")
    abbr('rgu', _expand_rgu)
    abbr('jd', '--json | delta_rg', position="anywhere", commands=('rg',))
    abbr('rg_json_delta', 'rg --json "%" | delta_rg', cursor_marker="%")
    abbr('rg_delta', 'rg --json "%" | delta_rg', cursor_marker="%")
    abbr('rg_json', 'rg --json "%"', cursor_marker="%")
    abbr('rg_files', 'rg --files')
    abbr('rg_files_no_match', 'rg --files-without-match')
    abbr('rg_files_with_matches', 'rg --files-with-matches')
    abbr('rg_debug', 'rg --debug')
    abbr('rg_trace', 'rg --trace')
    abbr('rg_stats', 'rg --stats')
    abbr('rg_multiline', 'rg --multiline --multiline-dotall')
    abbr('rgv', 'rg --invert-match "%"', cursor_marker="%")
    abbr('rgo', 'rg --only-matching "%"', cursor_marker="%")
    abbr('rgF', 'rg --fixed-strings "%"', cursor_marker="%")
    abbr('rgw', 'rg --word-regexp "%"', cursor_marker="%")
    abbr('-F', '--fixed-strings', position="anywhere", commands=('rg',))
    abbr('-v', '--invert-match', position="anywhere", commands=('rg',))
    abbr('-o', '--only-matching', position="anywhere", commands=('rg',))
    abbr('-w', '--word-regexp', position="anywhere", commands=('rg',))
    abbr('-g', '--glob', position="anywhere", commands=('rg',))
    abbr('-U', '--multiline', position="anywhere", commands=('rg',))
    abbr('sort_path', '--sort=path')
    abbr('sort_accessed', '--sort=accessed')
    abbr('sort_modified', '--sort=modified')
    abbr('sort_created', '--sort=created')
    abbr('lua_list_requires_unique', 'lua_list_all_requires | sort | uniq')
    abbr('lua_list_requires_count', 'lua_list_all_requires | sort | uniq -c | sort')
    abbr('lua_find_requires', 'lua_list_all_requires | sort | uniq | rg_grep "%"', cursor_marker="%")
    abbr('rgg', 'rg_grep "%"', cursor_marker="%")
