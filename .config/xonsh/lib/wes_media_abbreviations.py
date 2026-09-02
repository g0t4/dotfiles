"""Media abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import re

from wes_abbreviations import AbbreviationRegistry, abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
    unsupported_abbreviation,
)


FISH_FUNCTIONS = (
    'elgato_kill_other_account_streamdeck',  # Fish line 1683
    'show_pixel_color',  # Fish line 1700
    'show_pixel_column',  # Fish line 1708
    'quote_paths',  # Fish line 1723
    'video_editing_total_duration',  # Fish line 1729
    'abbr_thumbnail_check',  # Fish line 1747
    'abbr_check',  # Fish line 1759
    'abbr_videos_glob_for_current_dir',  # Fish line 1763
    'video_editing_1_check_audio',  # Fish line 1777
    'abbr_30fps',  # Fish line 1785
    'video_editing_2_convert_30fps',  # Fish line 1790
    'video_editing_extract_most_scene_change_thumbnails',  # Fish line 1795
    'abbr_mp4',  # Fish line 1801
    '_video_editing_ffmpeg_file_list',  # Fish line 1814
    '_get_first_file_dir',  # Fish line 1821
    '_get_output_file_based_on_first_file',  # Fish line 1825
    '_ffmpeg_concat',  # Fish line 1835
    '_find_first_video_file_for_extension',  # Fish line 1843
    '_find_first_video_file_any_type',  # Fish line 1853
    'video_editing_3_dropped_frames',  # Fish line 1867
    '_ffp',  # Fish line 1874
    '_ffi_trim',  # Fish line 1881
    '_ffi_pass_middle_to_new_out',  # Fish line 1890
    '_ffi_copy',  # Fish line 1900
    '_ffi_af',  # Fish line 1907
    '_ffi_vf',  # Fish line 1912
    'abbr_aio',  # Fish line 1925
    'video_editing_just_shift_to_mp4_one_video',  # Fish line 1931
    'path_stem',  # Fish line 1943
    'path_prefix_extension',  # Fish line 1948
    '_video_editing_aio_stage1',  # Fish line 1955
    '_video_editing_aio_thru_stage2',  # Fish line 1973
    'video_editing_aio',  # Fish line 1997
    'video_editing_gen_fcpxml',  # Fish line 2002
    'abbr_db',  # Fish line 2009
    'video_editing_boost_audio_dB_by',  # Fish line 2022
    '_screenshots_trash_secondary_display',  # Fish line 2339
    'move_screenshots_from_last_x_hours',  # Fish line 2347
    'find_huge_files',  # Fish line 2443
    'zedraw',  # Fish line 2627
    'zedfull',  # Fish line 2636
    'screencapture_ocr',  # Fish line 3141
    'screenpal_pid',  # Fish line 3458
    'streamdeck_svg2png_padded_square_only',  # Fish line 3465
    'string_indent',  # Fish line 3491
)


def register_media_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, '_150', fish_abbreviation('abbr_thumbnail_check'))  # Fish line 1746
    abbr(registry, '_1', fish_abbreviation('abbr_check'))  # Fish line 1758
    abbr(registry, '_2', fish_abbreviation('abbr_30fps'))  # Fish line 1784
    abbr(registry, '_mp4', fish_abbreviation('abbr_mp4'))  # Fish line 1800
    abbr(registry, '_3', 'video_editing_3_dropped_frames')  # Fish line 1866
    abbr(registry, 'ffp', fish_abbreviation('_ffp'))  # Fish line 1873
    abbr(registry, 'ffi_range', fish_abbreviation('_ffi_trim'))  # Fish line 1879
    abbr(registry, 'ffi_trim', fish_abbreviation('_ffi_trim'))  # Fish line 1880
    abbr(registry, 'ffi', fish_abbreviation('_ffi_copy'))  # Fish line 1898
    abbr(registry, 'ffi_copy', fish_abbreviation('_ffi_copy'))  # Fish line 1899
    abbr(registry, 'ffi_af', fish_abbreviation('_ffi_af'))  # Fish line 1906
    abbr(registry, 'ffi_vf', fish_abbreviation('_ffi_vf'))  # Fish line 1911
    abbr(registry, '_aio', fish_abbreviation('abbr_aio'))  # Fish line 1924
    abbr(registry, 'shift_only', 'for i in *.{mkv,mov}; video_editing_just_shift_to_mp4_one_video $i; end')  # Fish line 1930
    abbr(registry, re.compile('\\d+db'), fish_abbreviation('abbr_db'))  # Fish line 2008
    abbr(registry, 'virshl', 'virsh list')  # Fish line 2402
    abbr(registry, 'virshla', 'virsh list --all')  # Fish line 2403
    abbr(registry, 'virshd', 'virsh define')  # Fish line 2406
    abbr(registry, 'virshu', 'virsh undefine')  # Fish line 2407
    abbr(registry, 'virshdx', 'virsh dumpxml')  # Fish line 2408
    abbr(registry, 'vshn', 'virsh net-%', cursor_marker="%")  # Fish line 2418
    abbr(registry, 'virshnl', 'virsh net-list')  # Fish line 2419
    abbr(registry, 'virshndl', 'virsh net-dhcp-leases')  # Fish line 2421
    abbr(registry, 'cacl', 'cargo clean')  # Fish line 2427
    abbr(registry, 'cab', 'cargo build')  # Fish line 2428
    abbr(registry, 'car', 'cargo run')  # Fish line 2429
    abbr(registry, 'catest', 'cargo test')  # Fish line 2430
    abbr(registry, 'cabench', 'cargo bench')  # Fish line 2431
    abbr(registry, 'caa', 'cargo add')  # Fish line 2433
    abbr(registry, 'carm', 'cargo remove')  # Fish line 2434
    abbr(registry, 'cau', 'cargo update')  # Fish line 2435
    abbr(registry, 'canew', 'cargo new')  # Fish line 2437
    abbr(registry, 'cainit', 'cargo init')  # Fish line 2438
    abbr(registry, 'cas', 'cargo search')  # Fish line 2439
    abbr(registry, 'common', 'comm')  # Fish line 3133
    abbr(registry, 'common_left_only', 'comm -2 -3')  # Fish line 3135
    abbr(registry, 'common_right_only', 'comm -1 -2')  # Fish line 3136
    abbr(registry, 'common_both', 'comm -1 -3')  # Fish line 3137
    abbr(registry, 'intersection', 'comm -1 -3')  # Fish line 3138
    abbr(registry, 'java19', unsupported_abbreviation('java19', 'changes the current shell PATH'))  # Fish line 3439
    abbr(registry, 'jcmd_screenpal', 'jcmd \\$(screenpal_pid) ')  # Fish line 3442
    abbr(registry, 'mvnls', 'mvn dependenices:list')  # Fish line 3445
    abbr(registry, 'mvntree', 'mvn dependenices:tree')  # Fish line 3446
    abbr(registry, 'mvnc', 'mvn compile')  # Fish line 3447
    abbr(registry, 'mvnp', 'mvn package')  # Fish line 3448
    abbr(registry, 'mvnt', 'mvn test')  # Fish line 3449
    abbr(registry, 'spkill', 'pkill -ilf screenpal')  # Fish line 3452
    abbr(registry, 'spkilltray', 'echo disable tray app in partner properties file')  # Fish line 3454
    abbr(registry, 'splog', 'cat ~/Library/ScreenPal-v3/app-0.log')  # Fish line 3455
    abbr(registry, 'splogrm', 'rm ~/Library/ScreenPal-v3/app-0.log')  # Fish line 3456
