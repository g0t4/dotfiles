"""Misc abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr
from wes_misc_abbreviation_bridge import (
    unsupported_abbreviation,
)


FISH_FUNCTIONS = (
    'use_nvim_from_source',  # Fish line 3162
    'which_versions',  # Fish line 3521
    'km',  # Fish line 3537
    'secure_entry_pids',  # Fish line 3608
    'secure_entry_who',  # Fish line 3615
)


def register_misc_abbreviations():
    abbr('rsync_list_only_source_files', 'rsync --recursive --dry-run .')  # Fish line 3176
    abbr('rsync_quick', 'rsync --archive --delete --progress --stats --dry-run')  # Fish line 3204
    abbr('rsync_quick_dry_run', 'rsync --archive --delete --itemize-changes --dry-run')  # Fish line 3205
    abbr('rsync_checksum', 'rsync --archive --delete --checksum --progress --stats --dry-run')  # Fish line 3207
    abbr('rsync_checksum_dry_run', 'rsync --archive --delete --checksum --itemize-changes --stats --dry-run')  # Fish line 3208
    abbr('strs_lines', "string split '\\n'")  # Fish line 3216
    abbr('strs_comma', "string split ','")  # Fish line 3217
    abbr('strs_space', "string split ' '")  # Fish line 3218
    abbr('strs_tab', "string split '\\t'")  # Fish line 3219
    abbr('strs_colon', "string split ':'")  # Fish line 3220
    abbr('strs_pipe', "string split '|'")  # Fish line 3221
    abbr('strjoin_lines', "string join '\\n'")  # Fish line 3223
    abbr('-a', '--all', position="anywhere", commands=('string',))  # Fish line 3231
    abbr('-q', '--quiet', position="anywhere", commands=('string',))  # Fish line 3232
    abbr('-r', '--regex', position="anywhere", commands=('string',))  # Fish line 3233
    abbr('-v', '--invert', position="anywhere", commands=('string',))  # Fish line 3234
    abbr('strace_process', 'strace -f -e trace=process bash')  # Fish line 3281
    abbr('strace_file', 'strace -f -e trace=file bash')  # Fish line 3282
    abbr('strace_network', 'strace -f -e trace=network bash')  # Fish line 3283
    abbr('strace_signal', 'strace -f -e trace=signal bash')  # Fish line 3284
    abbr('strace_desc', 'strace -f -e trace=desc bash')  # Fish line 3285
    abbr('strace_ipc', 'strace -f -e trace=ipc bash')  # Fish line 3286
    abbr('strace_memory', 'strace -f -e trace=memory bash')  # Fish line 3287
    abbr('strace_all', 'strace -f -e trace=all bash')  # Fish line 3288
    abbr('strace_fds', 'strace -f -e fds=0,1,2 bash')  # Fish line 3290
    abbr('strace_fdSTDIN', 'strace -f -e fds=0 bash')  # Fish line 3291
    abbr('strace_fdSTDOUT', 'strace -f -e fds=1 bash')  # Fish line 3292
    abbr('strace_fdSTDERR', 'strace -f -e fds=2 bash')  # Fish line 3293
    abbr('strace_open', 'strace -f -e trace=/open bash')  # Fish line 3297
    abbr('strace_read', 'strace -f -e trace=/read bash')  # Fish line 3298
    abbr('strace_write', 'strace -f -e trace=/write bash')  # Fish line 3299
    abbr('stracec', 'strace -c -e trace=all sleep 1')  # Fish line 3302
    abbr('straceC', 'strace -C -e trace=all sleep 1')  # Fish line 3303
    abbr('fishc', "fish -c '%'", cursor_marker="%")  # Fish line 3306
    abbr('pPATH', unsupported_abbreviation('pPATH', 'uses Fish loop syntax to print the current shell PATH'))  # Fish line 3307
    abbr('date_s', 'date +%s')  # Fish line 3384
    abbr('cdr', 'cd $(_repo_root)')  # Fish line 3388
    abbr('orr', 'open $(_repo_root)')  # Fish line 3391
    abbr('oh', 'open .')  # Fish line 3392
    abbr('ch', 'code .')  # Fish line 3395
    abbr('cih', 'code-insiders .')  # Fish line 3396
    abbr('cr', 'code $(_repo_root)')  # Fish line 3397
    abbr('cir', 'code-insiders $(_repo_root)')  # Fish line 3398
    abbr('cie', 'code --inspect-extensions=9229 .')  # Fish line 3400
    abbr('cieb', 'code --inspect-brk-extensions=9229 .')  # Fish line 3401
    abbr('cs', 'cursor .')  # Fish line 3410
    abbr('csr', 'cursor $(_repo_root)')  # Fish line 3411
    abbr('zx', 'z -x')  # Fish line 3414
    abbr('tarx', 'tar -xf')  # Fish line 3417
    abbr('tarx_stdout', 'tar -O -xf')  # Fish line 3418
    abbr('tart', 'tar -tf')  # Fish line 3419
    abbr('tarc', 'tar --xz -cf')  # Fish line 3420
    abbr('tarcg', 'tar --gzip -cf')  # Fish line 3421
    abbr('tarcb', 'tar --bzip2 -cf')  # Fish line 3422
    abbr('jarx', 'jar -xf')  # Fish line 3425
    abbr('jart', 'jar -tf')  # Fish line 3426
    abbr('jartree', 'jar -tf %.jar | treeify', cursor_marker="%")  # Fish line 3427
    abbr('jaru', 'jar -uf')  # Fish line 3428
    abbr('jarc', 'jar -cf')  # Fish line 3429
    abbr('unzipx_stdout', 'unzip -p')  # Fish line 3433
    abbr('unzipl', 'unzip -l')  # Fish line 3434
    abbr('trim_trailing_new_line', 'perl -pe "chomp if eof" -i')  # Fish line 3516
    abbr('whicha', 'which -a')  # Fish line 3519
