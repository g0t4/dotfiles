"""Misc abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr
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


def register_misc_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'rsync_list_only_source_files', 'rsync --recursive --dry-run .')  # Fish line 3176
    abbr(registry, 'rsync_quick', 'rsync --archive --delete --progress --stats --dry-run')  # Fish line 3204
    abbr(registry, 'rsync_quick_dry_run', 'rsync --archive --delete --itemize-changes --dry-run')  # Fish line 3205
    abbr(registry, 'rsync_checksum', 'rsync --archive --delete --checksum --progress --stats --dry-run')  # Fish line 3207
    abbr(registry, 'rsync_checksum_dry_run', 'rsync --archive --delete --checksum --itemize-changes --stats --dry-run')  # Fish line 3208
    abbr(registry, 'strs_lines', "string split '\\n'")  # Fish line 3216
    abbr(registry, 'strs_comma', "string split ','")  # Fish line 3217
    abbr(registry, 'strs_space', "string split ' '")  # Fish line 3218
    abbr(registry, 'strs_tab', "string split '\\t'")  # Fish line 3219
    abbr(registry, 'strs_colon', "string split ':'")  # Fish line 3220
    abbr(registry, 'strs_pipe', "string split '|'")  # Fish line 3221
    abbr(registry, 'strjoin_lines', "string join '\\n'")  # Fish line 3223
    abbr(registry, '-a', '--all', position="anywhere", commands=('string',))  # Fish line 3231
    abbr(registry, '-q', '--quiet', position="anywhere", commands=('string',))  # Fish line 3232
    abbr(registry, '-r', '--regex', position="anywhere", commands=('string',))  # Fish line 3233
    abbr(registry, '-v', '--invert', position="anywhere", commands=('string',))  # Fish line 3234
    abbr(registry, 'strace_process', 'strace -f -e trace=process bash')  # Fish line 3281
    abbr(registry, 'strace_file', 'strace -f -e trace=file bash')  # Fish line 3282
    abbr(registry, 'strace_network', 'strace -f -e trace=network bash')  # Fish line 3283
    abbr(registry, 'strace_signal', 'strace -f -e trace=signal bash')  # Fish line 3284
    abbr(registry, 'strace_desc', 'strace -f -e trace=desc bash')  # Fish line 3285
    abbr(registry, 'strace_ipc', 'strace -f -e trace=ipc bash')  # Fish line 3286
    abbr(registry, 'strace_memory', 'strace -f -e trace=memory bash')  # Fish line 3287
    abbr(registry, 'strace_all', 'strace -f -e trace=all bash')  # Fish line 3288
    abbr(registry, 'strace_fds', 'strace -f -e fds=0,1,2 bash')  # Fish line 3290
    abbr(registry, 'strace_fdSTDIN', 'strace -f -e fds=0 bash')  # Fish line 3291
    abbr(registry, 'strace_fdSTDOUT', 'strace -f -e fds=1 bash')  # Fish line 3292
    abbr(registry, 'strace_fdSTDERR', 'strace -f -e fds=2 bash')  # Fish line 3293
    abbr(registry, 'strace_open', 'strace -f -e trace=/open bash')  # Fish line 3297
    abbr(registry, 'strace_read', 'strace -f -e trace=/read bash')  # Fish line 3298
    abbr(registry, 'strace_write', 'strace -f -e trace=/write bash')  # Fish line 3299
    abbr(registry, 'stracec', 'strace -c -e trace=all sleep 1')  # Fish line 3302
    abbr(registry, 'straceC', 'strace -C -e trace=all sleep 1')  # Fish line 3303
    abbr(registry, 'fishc', "fish -c '%'", cursor_marker="%")  # Fish line 3306
    abbr(registry, 'pPATH', unsupported_abbreviation('pPATH', 'uses Fish loop syntax to print the current shell PATH'))  # Fish line 3307
    abbr(registry, 'date_s', 'date +%s')  # Fish line 3384
    abbr(registry, 'cdr', 'cd $(_repo_root)')  # Fish line 3388
    abbr(registry, 'orr', 'open $(_repo_root)')  # Fish line 3391
    abbr(registry, 'oh', 'open .')  # Fish line 3392
    abbr(registry, 'ch', 'code .')  # Fish line 3395
    abbr(registry, 'cih', 'code-insiders .')  # Fish line 3396
    abbr(registry, 'cr', 'code $(_repo_root)')  # Fish line 3397
    abbr(registry, 'cir', 'code-insiders $(_repo_root)')  # Fish line 3398
    abbr(registry, 'cie', 'code --inspect-extensions=9229 .')  # Fish line 3400
    abbr(registry, 'cieb', 'code --inspect-brk-extensions=9229 .')  # Fish line 3401
    abbr(registry, 'cs', 'cursor .')  # Fish line 3410
    abbr(registry, 'csr', 'cursor $(_repo_root)')  # Fish line 3411
    abbr(registry, 'zx', 'z -x')  # Fish line 3414
    abbr(registry, 'tarx', 'tar -xf')  # Fish line 3417
    abbr(registry, 'tarx_stdout', 'tar -O -xf')  # Fish line 3418
    abbr(registry, 'tart', 'tar -tf')  # Fish line 3419
    abbr(registry, 'tarc', 'tar --xz -cf')  # Fish line 3420
    abbr(registry, 'tarcg', 'tar --gzip -cf')  # Fish line 3421
    abbr(registry, 'tarcb', 'tar --bzip2 -cf')  # Fish line 3422
    abbr(registry, 'jarx', 'jar -xf')  # Fish line 3425
    abbr(registry, 'jart', 'jar -tf')  # Fish line 3426
    abbr(registry, 'jartree', 'jar -tf %.jar | treeify', cursor_marker="%")  # Fish line 3427
    abbr(registry, 'jaru', 'jar -uf')  # Fish line 3428
    abbr(registry, 'jarc', 'jar -cf')  # Fish line 3429
    abbr(registry, 'unzipx_stdout', 'unzip -p')  # Fish line 3433
    abbr(registry, 'unzipl', 'unzip -l')  # Fish line 3434
    abbr(registry, 'trim_trailing_new_line', 'perl -pe "chomp if eof" -i')  # Fish line 3516
    abbr(registry, 'whicha', 'which -a')  # Fish line 3519
