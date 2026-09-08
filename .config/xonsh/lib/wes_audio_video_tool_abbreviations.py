"""Generated from fish/load_last_interactive_only/audio-vido-specific.fish; edit Fish/Zsh and rerun the generator."""

from wes_abbreviations import abbr
from wes_daily_tool_bridges import audio_abbreviation

SOURCE_FUNCTIONS = ('_exiftool_et', '_exiftool_etc', '_exiftool_ets', 'ffmpeg', 'ffprobe', 'ffplay', '_create_abbr_ff_help_filter', '_ff_volumedetect', '_ff_wav', '_ff_silencedetect', '_ff_astats', '_ff_astats_per_frame', '_ff_astats_overall', '_ff_astats_perchannel', '_ffprobe_expand_cmd', '_ffpshow_chapters', '_ffpshow_packets_video', '_ffpshow_packets_audio', '_ffpshow_streams', '_ffpshow_stream_groups', '_ffpshow_frames_video', '_ffpshow_frames_audio', '_ffpshow_format', '_ffpcount_frames', '_ffpcount_packets', '_ffpcount_both')


def register_audio_video_abbreviations():
    abbr('et', audio_abbreviation('_exiftool_et', cursor=False))  # Source line 3
    abbr('etc', audio_abbreviation('_exiftool_etc', cursor=False))  # Source line 9
    abbr('ets', audio_abbreviation('_exiftool_ets', cursor=False))  # Source line 15
    abbr('ff', 'ffmpeg')  # Source line 32
    abbr('ffm', 'ffmpeg')  # Source line 33
    abbr('ff_help_full', 'ffmpeg -h full')  # Source line 34
    abbr('ff_help_encoder', 'ffmpeg -h encoder=')  # Source line 35
    abbr('ff_help_decoder', 'ffmpeg -h decoder=')  # Source line 36
    abbr('ff_help_muxer', 'ffmpeg -h muxer=')  # Source line 37
    abbr('ff_help_demuxer', 'ffmpeg -h demuxer=')  # Source line 38
    abbr('ff_help_filter', 'ffmpeg -h filter=')  # Source line 39
    abbr('ff_help_protocol', 'ffmpeg -h protocol=')  # Source line 41
    abbr('no_output', '-f null -', position="anywhere", commands=('ffmpeg',))  # Source line 44
    abbr('ffp', 'ffprobe')  # Source line 48
    abbr('ffph', 'ffprobe -h full')  # Source line 49
    abbr('ffpshow', 'ffprobe -loglevel warning  -show_%', cursor_marker="%")  # Source line 54
    abbr('ff_help_filter_audio_acompressor', 'ffmpeg --help filter=acompressor && open https://ffmpeg.org/ffmpeg-filters.html#acompressor')  # Source line 74
    abbr('ff_help_filter_audio_aecho', 'ffmpeg --help filter=aecho && open https://ffmpeg.org/ffmpeg-filters.html#aecho')  # Source line 75
    abbr('ff_help_filter_audio_afftdn', 'ffmpeg --help filter=afftdn && open https://ffmpeg.org/ffmpeg-filters.html#afftdn')  # Source line 76
    abbr('ff_help_filter_audio_aformat', 'ffmpeg --help filter=aformat && open https://ffmpeg.org/ffmpeg-filters.html#aformat')  # Source line 77
    abbr('ff_help_filter_audio_aresample', 'ffmpeg --help filter=aresample && open https://ffmpeg.org/ffmpeg-filters.html#aresample')  # Source line 78
    abbr('ff_help_filter_audio_astats', 'ffmpeg --help filter=astats && open https://ffmpeg.org/ffmpeg-filters.html#astats')  # Source line 79
    abbr('ff_help_filter_audio_loudnorm', 'ffmpeg --help filter=loudnorm && open https://ffmpeg.org/ffmpeg-filters.html#loudnorm')  # Source line 80
    abbr('ff_help_filter_audio_silencedetect', 'ffmpeg --help filter=silencedetect && open https://ffmpeg.org/ffmpeg-filters.html#silencedetect')  # Source line 81
    abbr('ff_help_filter_audio_volumedetect', 'ffmpeg --help filter=volumedetect && open https://ffmpeg.org/ffmpeg-filters.html#volumedetect')  # Source line 82
    abbr('ff_help_filter_video_crop', 'ffmpeg --help filter=crop && open https://ffmpeg.org/ffmpeg-filters.html#crop')  # Source line 85
    abbr('ff_help_filter_video_drawtext', 'ffmpeg --help filter=drawtext && open https://ffmpeg.org/ffmpeg-filters.html#drawtext')  # Source line 86
    abbr('ff_help_filter_video_fps', 'ffmpeg --help filter=fps && open https://ffmpeg.org/ffmpeg-filters.html#fps')  # Source line 87
    abbr('ff_help_filter_video_hflip', 'ffmpeg --help filter=hflip && open https://ffmpeg.org/ffmpeg-filters.html#hflip')  # Source line 88
    abbr('ff_help_filter_video_overlay', 'ffmpeg --help filter=overlay && open https://ffmpeg.org/ffmpeg-filters.html#overlay')  # Source line 89
    abbr('ff_help_filter_video_scale', 'ffmpeg --help filter=scale && open https://ffmpeg.org/ffmpeg-filters.html#scale')  # Source line 90
    abbr('ff_help_filter_video_transpose', 'ffmpeg --help filter=transpose && open https://ffmpeg.org/ffmpeg-filters.html#transpose')  # Source line 91
    abbr('ff_help_filter_video_vflip', 'ffmpeg --help filter=vflip && open https://ffmpeg.org/ffmpeg-filters.html#vflip')  # Source line 92
    abbr('ff_help_filter_video_whisper', 'ffmpeg --help filter=whisper && open https://ffmpeg.org/ffmpeg-filters.html#whisper')  # Source line 93
    abbr('ff_volumedetect', audio_abbreviation('_ff_volumedetect', cursor=True))  # Source line 95
    abbr('ff_wav', audio_abbreviation('_ff_wav', cursor=True))  # Source line 101
    abbr('ff_silencedetect', audio_abbreviation('_ff_silencedetect', cursor=True))  # Source line 109
    abbr('ff_astats', audio_abbreviation('_ff_astats', cursor=True))  # Source line 116
    abbr('ff_astats_per_frame', audio_abbreviation('_ff_astats_per_frame', cursor=True))  # Source line 123
    abbr('ff_astats_overall', audio_abbreviation('_ff_astats_overall', cursor=True))  # Source line 130
    abbr('ff_astats_perchannel', audio_abbreviation('_ff_astats_perchannel', cursor=True))  # Source line 139
    abbr('ffpshow_chapters', audio_abbreviation('_ffpshow_chapters', cursor=True))  # Source line 162
    abbr('ffpshow_packets_video', audio_abbreviation('_ffpshow_packets_video', cursor=True))  # Source line 175
    abbr('ffpshow_packets_audio', audio_abbreviation('_ffpshow_packets_audio', cursor=True))  # Source line 180
    abbr('ffpshow_streams', audio_abbreviation('_ffpshow_streams', cursor=True))  # Source line 185
    abbr('ffpshow_stream_groups', audio_abbreviation('_ffpshow_stream_groups', cursor=True))  # Source line 190
    abbr('ffpshow_frames_video', audio_abbreviation('_ffpshow_frames_video', cursor=True))  # Source line 195
    abbr('ffpshow_frames_audio', audio_abbreviation('_ffpshow_frames_audio', cursor=True))  # Source line 200
    abbr('ffpshow_format', audio_abbreviation('_ffpshow_format', cursor=True))  # Source line 205
    abbr('ffpcount_frames', audio_abbreviation('_ffpcount_frames', cursor=True))  # Source line 211
    abbr('ffpcount_packets', audio_abbreviation('_ffpcount_packets', cursor=True))  # Source line 216
    abbr('ffpcount_both', audio_abbreviation('_ffpcount_both', cursor=True))  # Source line 221
    abbr('ffpshow_pixel_formats', 'ffprobe -loglevel warning  -show_pixel_formats')  # Source line 226
    abbr('ffpshow_version', 'ffprobe -loglevel warning  -show_program_version')  # Source line 227
    abbr('ffpl', 'ffplay')  # Source line 230
    abbr('ffplh', 'ffplay -h full')  # Source line 231
    abbr('sipsg', 'sips -g all')  # Source line 234
    abbr('sipsm', "sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -o new_image_file ")  # Source line 237
    abbr('sipsx', 'sips -x profile_extracted_here')  # Source line 238
    abbr('sipsf', 'sips --formats')  # Source line 241
