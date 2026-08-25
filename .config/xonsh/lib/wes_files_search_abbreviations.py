"""Generated from Fish's files-search-specific abbreviation inventory."""

from __future__ import annotations

import platform
import re

from wes_abbreviations import AbbreviationRegistry, AbbreviationResult, abbr
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


def register_files_search_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'mdfind_killall', 'killall mds mds_stores mds_worker Spotlight')
    abbr(registry, 'killall_spotlight', 'killall mds mds_stores mds_worker Spotlight')
    abbr(registry, 'mdfind_name', 'mdfind \'kMDItemFSName == "*%*"c\'', cursor_marker="%")
    abbr(registry, 'mdfind_path', 'mdfind \'kMDItemFSPath == "*%*"c\'', cursor_marker="%")
    abbr(registry, 'mdfind_dir', 'mdfind \'kMDItemContentType == "public.folder" && kMDItemFSName == "*%*"c\'', cursor_marker="%")
    abbr(registry, 'mdfind_live', 'mdfind -live \'kMDItemFSName == "*%*"c\'', cursor_marker="%")
    abbr(registry, 'mdfind_-name', "mdfind -name '%'", cursor_marker="%")
    abbr(registry, 'mdfind_contents', 'mdfind \'kMDItemTextContent == "*%*"c\'', cursor_marker="%")
    abbr(registry, 'mdfind_interpret_spotlight', "mdfind -interpret '%'", cursor_marker="%")
    abbr(registry, 'mdfind_today', "mdfind date:today '%'", cursor_marker="%")
    abbr(registry, 'mdfind_yesterday', "mdfind date:yesterday '%'", cursor_marker="%")
    abbr(registry, 'mdfind_this_week', "mdfind 'date:this week' '%'", cursor_marker="%")
    abbr(registry, 'mdfind_this_month', "mdfind 'date:this month' '%'", cursor_marker="%")
    abbr(registry, 'mdfind_this_year', "mdfind 'date:this year' '%'", cursor_marker="%")
    abbr(registry, 'mdfind_example_images_yesterday', 'mdfind "kind:image date:yesterday"')
    abbr(registry, 'mdfind_example_installed_apps', 'mdfind kMDItemAppStoreHasReceipt=1')
    abbr(registry, 'mdfind_example_tagged_green', 'mdfind "kMDItemUserTags = Green"')
    abbr(registry, 'mdfind_example_tagged_red', 'mdfind "kMDItemUserTags = Red"')
    abbr(registry, 'mdfind_example_tagged_yellow', 'mdfind "kMDItemUserTags = Yellow"')
    abbr(registry, 'mdfind_example_tagged_blue', 'mdfind "kMDItemUserTags = Blue"')
    abbr(registry, 'mdfind_example_count_readmes', 'mdfind -name readme.txt -count')
    abbr(registry, 'mdfind_example_homdir_last3days', "mdfind -onlyin ~ 'kMDItemFSContentChangeDate >= $time.today(-3)'")
    abbr(registry, 'mdfind_example_onlyin_PWD', 'mdfind -onlyin . -name pyproject.toml')
    abbr(registry, 'mdfind_example_images_keywords', 'mdfind "kind:images curl"')
    abbr(registry, 'mdfind_kind_app', "mdfind kind:app '%'", cursor_marker="%")
    abbr(registry, 'mdfind_kind_preferences', 'mdfind "kind:preferences"')
    abbr(registry, 'mdfind_kind_folder', 'mdfind "kind:folder"')
    abbr(registry, 'mdfind_kind_image', 'mdfind "kind:image"')
    abbr(registry, 'mdfind_kind_movie', 'mdfind "kind:movie"')
    abbr(registry, 'mdfind_kind_pdf', 'mdfind "kind:pdf"')
    abbr(registry, 'mdfind_kind_', 'mdfind "kind:%"', cursor_marker="%")
    abbr(registry, 'mdfind_kind_contact', 'kind:contact')
    abbr(registry, 'mdimport_list_attrs', "mdimport -A | rg_grep -i '%'", cursor_marker="%")
    abbr(registry, 'mdimport_list_importers', "mdimport -L | rg_grep -i '%'", cursor_marker="%")
    abbr(registry, 'mdimport_dump_schema', "mdimport -X | rg_grep -i '%'", cursor_marker="%")
    abbr(registry, 'mdls_item_attrs', "mdls -plist - '%' | bat -l xml", cursor_marker="%")
    abbr(registry, 'md_diagnose', 'sudo mddiagnose')
    abbr(registry, 'mdo', _unsupported_abbreviation('md_open', 'changes directory from an interactive fzf picker'))
    abbr(registry, 'mdcd', _unsupported_abbreviation('mdfind_cd_dir', 'changes directory from an interactive fzf picker'))
    abbr(registry, 'find', FIND_COMMAND)
    abbr(registry, 'finde', f"{FIND_COMMAND} . -executable")
    abbr(registry, 'findud', f"{FIND_COMMAND} '%' -user wesdemos", cursor_marker="%")
    abbr(registry, 'finduw', f"{FIND_COMMAND} '%' -user wes", cursor_marker="%")
    abbr(registry, 'g=w', '-not -perm -g=w', position="anywhere", commands=(FIND_COMMAND,))
    abbr(registry, 'o=w', '-not -perm -o=w', position="anywhere", commands=(FIND_COMMAND,))
    abbr(registry, 'fdnh', 'fd --no-hidden')
    abbr(registry, 'fdu', 'fd --unrestricted')
    abbr(registry, 'fd_nonegregious', 'fd --unrestricted --exclude .venv --exclude __pycache__ --exclude .rag --exclude .git --exclude node_modules | sort -h')
    abbr(registry, 'fd_nonegregious_diff', "diff_two_commands 'fd --unrestricted --exclude .venv --exclude __pycache__ --exclude .rag --exclude .git --exclude node_modules | sort -h' 'fd | sort -h'")
    abbr(registry, 'fdi', 'fd --ignore-case')
    abbr(registry, 'fdF', 'fd --fixed-strings')
    abbr(registry, 'fd_ext', 'fd --extension')
    abbr(registry, 'fdE', 'fd --exclude')
    abbr(registry, 'and', '--and', position="anywhere", commands=('fd',))
    abbr(registry, 'fdh', 'fd --help')
    abbr(registry, '-0', '--print0', position="anywhere", commands=('fd',))
    abbr(registry, '-a', '--absolute-path', position="anywhere", commands=('fd',))
    abbr(registry, '-C', '--base-directory', position="anywhere", commands=('fd',))
    abbr(registry, '-c', '--color', position="anywhere", commands=('fd',))
    abbr(registry, '-d', '--max-depth', position="anywhere", commands=('fd',))
    abbr(registry, '-E', '--exclude', position="anywhere", commands=('fd',))
    abbr(registry, '-e', '--extension', position="anywhere", commands=('fd',))
    abbr(registry, '-F', '--fixed-strings', position="anywhere", commands=('fd',))
    abbr(registry, '-F', '--fixed-strings', position="anywhere", commands=('fd',))
    abbr(registry, '-g', '--glob', position="anywhere", commands=('fd',))
    abbr(registry, '-h', '--help', position="anywhere", commands=('fd',))
    abbr(registry, '-H', '--hidden', position="anywhere", commands=('fd',))
    abbr(registry, '-i', '--ignore-case', position="anywhere", commands=('fd',))
    abbr(registry, '-I', '--no-ignore', position="anywhere", commands=('fd',))
    abbr(registry, '-j', '--threads', position="anywhere", commands=('fd',))
    abbr(registry, '-L', '--follow', position="anywhere", commands=('fd',))
    abbr(registry, '-l', '--list-details', position="anywhere", commands=('fd',))
    abbr(registry, '-o', '--owner', position="anywhere", commands=('fd',))
    abbr(registry, '-p', '--full-path', position="anywhere", commands=('fd',))
    abbr(registry, '-q', '--quiet', position="anywhere", commands=('fd',))
    abbr(registry, '-s', '--case-sensitive', position="anywhere", commands=('fd',))
    abbr(registry, '-S', '--size', position="anywhere", commands=('fd',))
    abbr(registry, '-t', '--type', position="anywhere", commands=('fd',))
    abbr(registry, '-u', '--unrestricted', position="anywhere", commands=('fd',))
    abbr(registry, '-V', '--version', position="anywhere", commands=('fd',))
    abbr(registry, '-x', '--exec', position="anywhere", commands=('fd',))
    abbr(registry, '-X', '--exec-batch', position="anywhere", commands=('fd',))
    abbr(registry, 'fdabs', 'fd --absolute-path')
    abbr(registry, 'fdl', 'fd --list-details')
    abbr(registry, 'fdfp', 'fd --full-path')
    abbr(registry, re.compile('fd\\d+'), _expand_fd_depth)
    abbr(registry, 'fd_changed_within', 'fd --changed-within "%"', cursor_marker="%")
    abbr(registry, 'fd_changed_within_hours', 'fd --changed-within "% h"', cursor_marker="%")
    abbr(registry, 'fd_changed_within_days', 'fd --changed-within "% d"', cursor_marker="%")
    abbr(registry, 'fd_changed_within_weeks', 'fd --changed-within "% weeks"', cursor_marker="%")
    abbr(registry, 'fd_changed_within_months', 'fd --changed-within "% months"', cursor_marker="%")
    abbr(registry, 'fd_changed_within_years', 'fd --changed-within "% years"', cursor_marker="%")
    abbr(registry, 'fd_changed_before', 'fd --changed-before "%"', cursor_marker="%")
    abbr(registry, 'fdx', 'fd --exec')
    abbr(registry, 'fdxb', 'fd --exec-batch')
    abbr(registry, 'fdq', 'fd --quiet')
    abbr(registry, '-F', '--fixed-strings', position="anywhere", commands=('fd',))
    abbr(registry, 'fdtb', 'fd --type block-device')
    abbr(registry, 'fdtc', 'fd --type char-device')
    abbr(registry, 'fdtd', 'fd --type dir')
    abbr(registry, 'fdte', 'fd --type empty')
    abbr(registry, 'fdtf', 'fd --type file')
    abbr(registry, 'fdtl', 'fd --type symlink')
    abbr(registry, 'fdtp', 'fd --type pipe')
    abbr(registry, 'fdts', 'fd --type socket')
    abbr(registry, 'fdtx', 'fd --type executable')
    abbr(registry, 'list_filetype_extensions', "fd --type file | awk -F. 'NF > 1 {print $NF}' | sort | uniq -c | sort")
    abbr(registry, 'fd_extensionless_files', 'fd "^[^\\.]+\\$" --type file')
    abbr(registry, 'rgc', 'rg --case-sensitive "%"', cursor_marker="%")
    abbr(registry, 'rgi', 'rg -i "%"', cursor_marker="%")
    abbr(registry, 'rgh', 'rg --hidden "%"', cursor_marker="%")
    abbr(registry, 'grep', 'rg_grep "%"', cursor_marker="%")
    abbr(registry, 'h', 'history show all | bat -l xonsh --color always | less -F')
    abbr(registry, 'hgr', 'history show all | rg_grep "%"', cursor_marker="%")
    abbr(registry, 'hm', 'history pull')
    abbr(registry, 'hd', 'history delete "%"', cursor_marker="%")
    abbr(registry, 'rgu', _expand_rgu)
    abbr(registry, 'jd', '--json | delta_rg', position="anywhere", commands=('rg',))
    abbr(registry, 'rg_json_delta', 'rg --json "%" | delta_rg', cursor_marker="%")
    abbr(registry, 'rg_delta', 'rg --json "%" | delta_rg', cursor_marker="%")
    abbr(registry, 'rg_json', 'rg --json "%"', cursor_marker="%")
    abbr(registry, 'rg_files', 'rg --files')
    abbr(registry, 'rg_files_no_match', 'rg --files-without-match')
    abbr(registry, 'rg_files_with_matches', 'rg --files-with-matches')
    abbr(registry, 'rg_debug', 'rg --debug')
    abbr(registry, 'rg_trace', 'rg --trace')
    abbr(registry, 'rg_stats', 'rg --stats')
    abbr(registry, 'rg_multiline', 'rg --multiline --multiline-dotall')
    abbr(registry, 'rgv', 'rg --invert-match "%"', cursor_marker="%")
    abbr(registry, 'rgo', 'rg --only-matching "%"', cursor_marker="%")
    abbr(registry, 'rgF', 'rg --fixed-strings "%"', cursor_marker="%")
    abbr(registry, 'rgw', 'rg --word-regexp "%"', cursor_marker="%")
    abbr(registry, '-F', '--fixed-strings', position="anywhere", commands=('rg',))
    abbr(registry, '-v', '--invert-match', position="anywhere", commands=('rg',))
    abbr(registry, '-o', '--only-matching', position="anywhere", commands=('rg',))
    abbr(registry, '-w', '--word-regexp', position="anywhere", commands=('rg',))
    abbr(registry, '-g', '--glob', position="anywhere", commands=('rg',))
    abbr(registry, '-U', '--multiline', position="anywhere", commands=('rg',))
    abbr(registry, 'sort_path', '--sort=path')
    abbr(registry, 'sort_accessed', '--sort=accessed')
    abbr(registry, 'sort_modified', '--sort=modified')
    abbr(registry, 'sort_created', '--sort=created')
    abbr(registry, 'lua_list_requires_unique', 'lua_list_all_requires | sort | uniq')
    abbr(registry, 'lua_list_requires_count', 'lua_list_all_requires | sort | uniq -c | sort')
    abbr(registry, 'lua_find_requires', 'lua_list_all_requires | sort | uniq | rg_grep "%"', cursor_marker="%")
    abbr(registry, 'rgg', 'rg_grep "%"', cursor_marker="%")
