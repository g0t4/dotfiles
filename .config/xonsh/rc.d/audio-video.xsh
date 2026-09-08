"""Audio/video helpers; dynamic expansions retain their Fish implementations."""

from xonsh.built_ins import XSH
from wes_audio_video_tool_abbreviations import SOURCE_FUNCTIONS, register_audio_video_abbreviations
from wes_misc_functions import fish_command_alias
from wes_abbreviations import abbr

register_audio_video_abbreviations()


def _create_abbr_ff_help_filter(args, **_):
    kind, name = args
    abbr(f"ff_help_filter_{kind}_{name}",
         f"ffmpeg --help filter={name} && open https://ffmpeg.org/ffmpeg-filters.html#{name}")


for _audio_function in SOURCE_FUNCTIONS:
    if _audio_function in {"ffmpeg", "ffprobe", "ffplay"}:
        XSH.aliases[_audio_function] = [_audio_function, "-hide_banner"]
    elif _audio_function == "_create_abbr_ff_help_filter":
        XSH.aliases[_audio_function] = _create_abbr_ff_help_filter
    else:
        XSH.aliases[_audio_function] = fish_command_alias(_audio_function)
