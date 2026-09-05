"""Media abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import re

from wes_abbreviations import abbr
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


def register_media_abbreviations():
    abbr('_150', fish_abbreviation('abbr_thumbnail_check'))  # Fish line 1746
    abbr('_1', fish_abbreviation('abbr_check'))  # Fish line 1758
    abbr('_2', fish_abbreviation('abbr_30fps'))  # Fish line 1784
    abbr('_mp4', fish_abbreviation('abbr_mp4'))  # Fish line 1800
    abbr('_3', 'video_editing_3_dropped_frames')  # Fish line 1866
    abbr('ffp', fish_abbreviation('_ffp'))  # Fish line 1873
    abbr('ffi_range', fish_abbreviation('_ffi_trim'))  # Fish line 1879
    abbr('ffi_trim', fish_abbreviation('_ffi_trim'))  # Fish line 1880
    abbr('ffi', fish_abbreviation('_ffi_copy'))  # Fish line 1898
    abbr('ffi_copy', fish_abbreviation('_ffi_copy'))  # Fish line 1899
    abbr('ffi_af', fish_abbreviation('_ffi_af'))  # Fish line 1906
    abbr('ffi_vf', fish_abbreviation('_ffi_vf'))  # Fish line 1911
    abbr('_aio', fish_abbreviation('abbr_aio'))  # Fish line 1924
    abbr('shift_only', 'for i in *.{mkv,mov}; video_editing_just_shift_to_mp4_one_video $i; end')  # Fish line 1930
    abbr(re.compile('\\d+db'), fish_abbreviation('abbr_db'))  # Fish line 2008
    abbr('virshl', 'virsh list')  # Fish line 2402
    abbr('virshla', 'virsh list --all')  # Fish line 2403
    abbr('virshd', 'virsh define')  # Fish line 2406
    abbr('virshu', 'virsh undefine')  # Fish line 2407
    abbr('virshdx', 'virsh dumpxml')  # Fish line 2408
    abbr('vshn', 'virsh net-%', cursor_marker="%")  # Fish line 2418
    abbr('virshnl', 'virsh net-list')  # Fish line 2419
    abbr('virshndl', 'virsh net-dhcp-leases')  # Fish line 2421
    abbr('cacl', 'cargo clean')  # Fish line 2427
    abbr('cab', 'cargo build')  # Fish line 2428
    abbr('car', 'cargo run')  # Fish line 2429
    abbr('catest', 'cargo test')  # Fish line 2430
    abbr('cabench', 'cargo bench')  # Fish line 2431
    abbr('caa', 'cargo add')  # Fish line 2433
    abbr('carm', 'cargo remove')  # Fish line 2434
    abbr('cau', 'cargo update')  # Fish line 2435
    abbr('canew', 'cargo new')  # Fish line 2437
    abbr('cainit', 'cargo init')  # Fish line 2438
    abbr('cas', 'cargo search')  # Fish line 2439
    abbr('common', 'comm')  # Fish line 3133
    abbr('common_left_only', 'comm -2 -3')  # Fish line 3135
    abbr('common_right_only', 'comm -1 -2')  # Fish line 3136
    abbr('common_both', 'comm -1 -3')  # Fish line 3137
    abbr('intersection', 'comm -1 -3')  # Fish line 3138
    abbr('java19', unsupported_abbreviation('java19', 'changes the current shell PATH'))  # Fish line 3439
    abbr('jcmd_screenpal', 'jcmd \\$(screenpal_pid) ')  # Fish line 3442
    abbr('mvnls', 'mvn dependenices:list')  # Fish line 3445
    abbr('mvntree', 'mvn dependenices:tree')  # Fish line 3446
    abbr('mvnc', 'mvn compile')  # Fish line 3447
    abbr('mvnp', 'mvn package')  # Fish line 3448
    abbr('mvnt', 'mvn test')  # Fish line 3449
    abbr('spkill', 'pkill -ilf screenpal')  # Fish line 3452
    abbr('spkilltray', 'echo disable tray app in partner properties file')  # Fish line 3454
    abbr('splog', 'cat ~/Library/ScreenPal-v3/app-0.log')  # Fish line 3455
    abbr('splogrm', 'rm ~/Library/ScreenPal-v3/app-0.log')  # Fish line 3456
