"""Misc abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr
from wes_misc_abbreviation_bridge import (
    unsupported_abbreviation,
)


FISH_FUNCTIONS = (
    'use_nvim_from_source',
    'which_versions',
    'km',
    'secure_entry_pids',
    'secure_entry_who',
)


def register_misc_abbreviations():
    abbr('rsync_list_only_source_files', 'rsync --recursive --dry-run .')
    abbr('rsync_quick', 'rsync --archive --delete --progress --stats --dry-run')
    abbr('rsync_quick_dry_run', 'rsync --archive --delete --itemize-changes --dry-run')
    abbr('rsync_checksum', 'rsync --archive --delete --checksum --progress --stats --dry-run')
    abbr('rsync_checksum_dry_run', 'rsync --archive --delete --checksum --itemize-changes --stats --dry-run')
    abbr('strs_lines', "string split '\\n'")
    abbr('strs_comma', "string split ','")
    abbr('strs_space', "string split ' '")
    abbr('strs_tab', "string split '\\t'")
    abbr('strs_colon', "string split ':'")
    abbr('strs_pipe', "string split '|'")
    abbr('strjoin_lines', "string join '\\n'")
    abbr('-a', '--all', position="anywhere", commands=('string',))
    abbr('-q', '--quiet', position="anywhere", commands=('string',))
    abbr('-r', '--regex', position="anywhere", commands=('string',))
    abbr('-v', '--invert', position="anywhere", commands=('string',))
    abbr('strace_process', 'strace -f -e trace=process bash')
    abbr('strace_file', 'strace -f -e trace=file bash')
    abbr('strace_network', 'strace -f -e trace=network bash')
    abbr('strace_signal', 'strace -f -e trace=signal bash')
    abbr('strace_desc', 'strace -f -e trace=desc bash')
    abbr('strace_ipc', 'strace -f -e trace=ipc bash')
    abbr('strace_memory', 'strace -f -e trace=memory bash')
    abbr('strace_all', 'strace -f -e trace=all bash')
    abbr('strace_fds', 'strace -f -e fds=0,1,2 bash')
    abbr('strace_fdSTDIN', 'strace -f -e fds=0 bash')
    abbr('strace_fdSTDOUT', 'strace -f -e fds=1 bash')
    abbr('strace_fdSTDERR', 'strace -f -e fds=2 bash')
    abbr('strace_open', 'strace -f -e trace=/open bash')
    abbr('strace_read', 'strace -f -e trace=/read bash')
    abbr('strace_write', 'strace -f -e trace=/write bash')
    abbr('stracec', 'strace -c -e trace=all sleep 1')
    abbr('straceC', 'strace -C -e trace=all sleep 1')
    abbr('fishc', "fish -c '%'", cursor_marker="%")
    abbr('pPATH', unsupported_abbreviation('pPATH', 'uses Fish loop syntax to print the current shell PATH'))
    abbr('date_s', 'date +%s')
    abbr('cdr', 'cd $(_repo_root)')
    abbr('orr', 'open $(_repo_root)')
    abbr('oh', 'open .')
    abbr('ch', 'code .')
    abbr('cih', 'code-insiders .')
    abbr('cr', 'code $(_repo_root)')
    abbr('cir', 'code-insiders $(_repo_root)')
    abbr('cie', 'code --inspect-extensions=9229 .')
    abbr('cieb', 'code --inspect-brk-extensions=9229 .')
    abbr('cs', 'cursor .')
    abbr('csr', 'cursor $(_repo_root)')
    abbr('zx', 'z -x')
    abbr('tarx', 'tar -xf')
    abbr('tarx_stdout', 'tar -O -xf')
    abbr('tart', 'tar -tf')
    abbr('tarc', 'tar --xz -cf')
    abbr('tarcg', 'tar --gzip -cf')
    abbr('tarcb', 'tar --bzip2 -cf')
    abbr('jarx', 'jar -xf')
    abbr('jart', 'jar -tf')
    abbr('jartree', 'jar -tf %.jar | treeify', cursor_marker="%")
    abbr('jaru', 'jar -uf')
    abbr('jarc', 'jar -cf')
    abbr('unzipx_stdout', 'unzip -p')
    abbr('unzipl', 'unzip -l')
    abbr('nixpls', 'nix profile list')
    abbr('trim_trailing_new_line', 'perl -pe "chomp if eof" -i')
    abbr('whicha', 'which -a')
