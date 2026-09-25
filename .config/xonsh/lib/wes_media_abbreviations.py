"""generated from Fish"""

from __future__ import annotations

import re

from wes_abbreviations import abbr
from wes_fish_migration import (
    abbr_from_fish_function,
    unsupported_abbreviation,
)


FISH_FUNCTIONS = (
    'elgato_kill_other_account_streamdeck',
    'show_pixel_color',
    'show_pixel_column',
    'quote_paths',
    'video_editing_total_duration',
    'abbr_thumbnail_check',
    'abbr_check',
    'abbr_videos_glob_for_current_dir',
    'video_editing_1_check_audio',
    'abbr_30fps',
    'video_editing_2_convert_30fps',
    'video_editing_extract_most_scene_change_thumbnails',
    'abbr_mp4',
    '_video_editing_ffmpeg_file_list',
    '_get_first_file_dir',
    '_get_output_file_based_on_first_file',
    '_ffmpeg_concat',
    '_find_first_video_file_for_extension',
    '_find_first_video_file_any_type',
    'video_editing_3_dropped_frames',
    '_ffp',
    '_ffi_trim',
    '_ffi_pass_middle_to_new_out',
    '_ffi_copy',
    '_ffi_af',
    '_ffi_vf',
    'abbr_aio',
    'video_editing_just_shift_to_mp4_one_video',
    'path_stem',
    'path_prefix_extension',
    '_video_editing_aio_stage1',
    '_video_editing_aio_thru_stage2',
    'video_editing_aio',
    'video_editing_gen_fcpxml',
    'abbr_db',
    'video_editing_boost_audio_dB_by',
    '_screenshots_trash_secondary_display',
    'move_screenshots_from_last_x_hours',
    'find_huge_files',
    'zedraw',
    'zedfull',
    'screencapture_ocr',
    'screenpal_pid',
    'streamdeck_svg2png_padded_square_only',
    'string_indent',
)


def register_wes_media_abbreviations():
    abbr('_150', abbr_from_fish_function('abbr_thumbnail_check'))
    abbr('_1', abbr_from_fish_function('abbr_check'))
    abbr('_2', abbr_from_fish_function('abbr_30fps'))
    abbr('_mp4', abbr_from_fish_function('abbr_mp4'))
    abbr('_3', 'video_editing_3_dropped_frames')
    abbr('ffp', abbr_from_fish_function('_ffp'))
    abbr('ffi_range', abbr_from_fish_function('_ffi_trim'))
    abbr('ffi_trim', abbr_from_fish_function('_ffi_trim'))
    abbr('ffi', abbr_from_fish_function('_ffi_copy'))
    abbr('ffi_copy', abbr_from_fish_function('_ffi_copy'))
    abbr('ffi_af', abbr_from_fish_function('_ffi_af'))
    abbr('ffi_vf', abbr_from_fish_function('_ffi_vf'))
    abbr('_aio', abbr_from_fish_function('abbr_aio'))
    abbr('shift_only', 'for i in *.{mkv,mov}; video_editing_just_shift_to_mp4_one_video $i; end')
    abbr(re.compile('\\d+db'), abbr_from_fish_function('abbr_db'))
    abbr('virshl', 'virsh list')
    abbr('virshla', 'virsh list --all')
    abbr('virshd', 'virsh define')
    abbr('virshu', 'virsh undefine')
    abbr('virshdx', 'virsh dumpxml')
    abbr('vshn', 'virsh net-%', cursor_marker="%")
    abbr('virshnl', 'virsh net-list')
    abbr('virshndl', 'virsh net-dhcp-leases')
    abbr('cacl', 'cargo clean')
    abbr('cab', 'cargo build')
    abbr('car', 'cargo run')
    abbr('catest', 'cargo test')
    abbr('cabench', 'cargo bench')
    abbr('caa', 'cargo add')
    abbr('carm', 'cargo remove')
    abbr('cau', 'cargo update')
    abbr('canew', 'cargo new')
    abbr('cainit', 'cargo init')
    abbr('cas', 'cargo search')
    abbr('common', 'comm')
    abbr('common_left_only', 'comm -2 -3')
    abbr('common_right_only', 'comm -1 -2')
    abbr('common_both', 'comm -1 -3')
    abbr('intersection', 'comm -1 -3')
    abbr('java19', unsupported_abbreviation('java19', 'changes the current shell PATH'))
    abbr('jcmd_screenpal', 'jcmd \\$(screenpal_pid) ')
    abbr('mvnls', 'mvn dependenices:list')
    abbr('mvntree', 'mvn dependenices:tree')
    abbr('mvnc', 'mvn compile')
    abbr('mvnp', 'mvn package')
    abbr('mvnt', 'mvn test')
    abbr('spkill', 'pkill -ilf screenpal')
    abbr('spkilltray', 'echo disable tray app in partner properties file')
    abbr('splog', 'cat ~/Library/ScreenPal-v3/app-0.log')
    abbr('splogrm', 'rm ~/Library/ScreenPal-v3/app-0.log')
