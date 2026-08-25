"""Media abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import platform
import re


from wes_abbreviations import AbbreviationRegistry, abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
    unsupported_abbreviation,
)



MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"
SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"


FISH_FUNCTIONS = (
    'elgato_kill_other_account_streamdeck',  # Fish line 1686
    'show_pixel_color',  # Fish line 1703
    'show_pixel_column',  # Fish line 1711
    'quote_paths',  # Fish line 1726
    'video_editing_total_duration',  # Fish line 1732
    'abbr_thumbnail_check',  # Fish line 1750
    'abbr_check',  # Fish line 1762
    'abbr_videos_glob_for_current_dir',  # Fish line 1766
    'video_editing_1_check_audio',  # Fish line 1780
    'abbr_30fps',  # Fish line 1788
    'video_editing_2_convert_30fps',  # Fish line 1793
    'video_editing_extract_most_scene_change_thumbnails',  # Fish line 1798
    'abbr_mp4',  # Fish line 1804
    '_video_editing_ffmpeg_file_list',  # Fish line 1817
    '_get_first_file_dir',  # Fish line 1824
    '_get_output_file_based_on_first_file',  # Fish line 1828
    '_ffmpeg_concat',  # Fish line 1838
    '_find_first_video_file_for_extension',  # Fish line 1846
    '_find_first_video_file_any_type',  # Fish line 1856
    'video_editing_3_dropped_frames',  # Fish line 1870
    '_ffp',  # Fish line 1877
    '_ffi_trim',  # Fish line 1884
    '_ffi_pass_middle_to_new_out',  # Fish line 1893
    '_ffi_copy',  # Fish line 1903
    '_ffi_af',  # Fish line 1910
    '_ffi_vf',  # Fish line 1915
    'abbr_aio',  # Fish line 1928
    'video_editing_just_shift_to_mp4_one_video',  # Fish line 1934
    'path_stem',  # Fish line 1946
    'path_prefix_extension',  # Fish line 1951
    '_video_editing_aio_stage1',  # Fish line 1958
    '_video_editing_aio_thru_stage2',  # Fish line 1976
    'video_editing_aio',  # Fish line 2000
    'video_editing_gen_fcpxml',  # Fish line 2005
    'abbr_db',  # Fish line 2012
    'video_editing_boost_audio_dB_by',  # Fish line 2025
    '_screenshots_trash_secondary_display',  # Fish line 2342
    'move_screenshots_from_last_x_hours',  # Fish line 2350
    'find_huge_files',  # Fish line 2446
    'zedraw',  # Fish line 2630
    'zedfull',  # Fish line 2639
    'screencapture_ocr',  # Fish line 3144
    'screenpal_pid',  # Fish line 3461
    'streamdeck_svg2png_padded_square_only',  # Fish line 3468
    'string_indent',  # Fish line 3494
)


def register_media_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, '_150', fish_abbreviation('abbr_thumbnail_check'))  # Fish line 1749
    abbr(registry, '_1', fish_abbreviation('abbr_check'))  # Fish line 1761
    abbr(registry, '_2', fish_abbreviation('abbr_30fps'))  # Fish line 1787
    abbr(registry, '_mp4', fish_abbreviation('abbr_mp4'))  # Fish line 1803
    abbr(registry, '_3', 'video_editing_3_dropped_frames')  # Fish line 1869
    abbr(registry, 'ffp', fish_abbreviation('_ffp'))  # Fish line 1876
    abbr(registry, 'ffi_range', fish_abbreviation('_ffi_trim'))  # Fish line 1882
    abbr(registry, 'ffi_trim', fish_abbreviation('_ffi_trim'))  # Fish line 1883
    abbr(registry, 'ffi', fish_abbreviation('_ffi_copy'))  # Fish line 1901
    abbr(registry, 'ffi_copy', fish_abbreviation('_ffi_copy'))  # Fish line 1902
    abbr(registry, 'ffi_af', fish_abbreviation('_ffi_af'))  # Fish line 1909
    abbr(registry, 'ffi_vf', fish_abbreviation('_ffi_vf'))  # Fish line 1914
    abbr(registry, '_aio', fish_abbreviation('abbr_aio'))  # Fish line 1927
    abbr(registry, 'shift_only', 'for i in *.{mkv,mov}; video_editing_just_shift_to_mp4_one_video $i; end')  # Fish line 1933
    abbr(registry, re.compile('\\d+db'), fish_abbreviation('abbr_db'))  # Fish line 2011
    abbr(registry, 'virshl', 'virsh list')  # Fish line 2405
    abbr(registry, 'virshla', 'virsh list --all')  # Fish line 2406
    abbr(registry, 'virshd', 'virsh define')  # Fish line 2409
    abbr(registry, 'virshu', 'virsh undefine')  # Fish line 2410
    abbr(registry, 'virshdx', 'virsh dumpxml')  # Fish line 2411
    abbr(registry, 'vshn', 'virsh net-%', cursor_marker="%")  # Fish line 2421
    abbr(registry, 'virshnl', 'virsh net-list')  # Fish line 2422
    abbr(registry, 'virshndl', 'virsh net-dhcp-leases')  # Fish line 2424
    abbr(registry, 'cacl', 'cargo clean')  # Fish line 2430
    abbr(registry, 'cab', 'cargo build')  # Fish line 2431
    abbr(registry, 'car', 'cargo run')  # Fish line 2432
    abbr(registry, 'catest', 'cargo test')  # Fish line 2433
    abbr(registry, 'cabench', 'cargo bench')  # Fish line 2434
    abbr(registry, 'caa', 'cargo add')  # Fish line 2436
    abbr(registry, 'carm', 'cargo remove')  # Fish line 2437
    abbr(registry, 'cau', 'cargo update')  # Fish line 2438
    abbr(registry, 'canew', 'cargo new')  # Fish line 2440
    abbr(registry, 'cainit', 'cargo init')  # Fish line 2441
    abbr(registry, 'cas', 'cargo search')  # Fish line 2442
    abbr(registry, 'common', 'comm')  # Fish line 3136
    abbr(registry, 'common_left_only', 'comm -2 -3')  # Fish line 3138
    abbr(registry, 'common_right_only', 'comm -1 -2')  # Fish line 3139
    abbr(registry, 'common_both', 'comm -1 -3')  # Fish line 3140
    abbr(registry, 'intersection', 'comm -1 -3')  # Fish line 3141
    abbr(registry, 'java19', unsupported_abbreviation('java19', 'changes the current shell PATH'))  # Fish line 3442
    abbr(registry, 'jcmd_screenpal', 'jcmd \\$(screenpal_pid) ')  # Fish line 3445
    abbr(registry, 'mvnls', 'mvn dependenices:list')  # Fish line 3448
    abbr(registry, 'mvntree', 'mvn dependenices:tree')  # Fish line 3449
    abbr(registry, 'mvnc', 'mvn compile')  # Fish line 3450
    abbr(registry, 'mvnp', 'mvn package')  # Fish line 3451
    abbr(registry, 'mvnt', 'mvn test')  # Fish line 3452
    abbr(registry, 'spkill', 'pkill -ilf screenpal')  # Fish line 3455
    abbr(registry, 'spkilltray', 'echo disable tray app in partner properties file')  # Fish line 3457
    abbr(registry, 'splog', 'cat ~/Library/ScreenPal-v3/app-0.log')  # Fish line 3458
    abbr(registry, 'splogrm', 'rm ~/Library/ScreenPal-v3/app-0.log')  # Fish line 3459
