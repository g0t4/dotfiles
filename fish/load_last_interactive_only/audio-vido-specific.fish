### *** exiftool

abbr et --function _exiftool_et
function _exiftool_et
    set file (_find_first_video_file_any_type; or echo _)
    echo -n "grc exiftool $file"
end

abbr etc --function _exiftool_etc
function _exiftool_etc
    set file (_find_first_video_file_any_type; or echo _)
    echo -n "grc exiftool -common -duration -AudioFormat -CompressorName -AudioSampleRate $file"
end

abbr ets --function _exiftool_ets
function _exiftool_ets
    set file (_find_first_video_file_any_type; or echo _)
    echo -n "grc exiftool -s $file"
end

### *** ffmpeg et al
function ffmpeg
    command ffmpeg -hide_banner $argv
end
function ffprobe
    command ffprobe -hide_banner $argv
end
function ffplay
    command ffplay -hide_banner $argv
end
# FYI some of these are reminders when I revisit ffmpeg (i.e. to know what to get help for)
abbr ff ffmpeg
abbr ffm ffmpeg
abbr ff_help_full "ffmpeg -h full" # full help is far superior to ffmpeg-all which doesn't really show device specific options/devices/filters/formats/etc
abbr ff_help_encoder "ffmpeg -h encoder="
abbr ff_help_decoder "ffmpeg -h decoder="
abbr ff_help_muxer "ffmpeg -h muxer="
abbr ff_help_demuxer "ffmpeg -h demuxer="
abbr ff_help_filter "ffmpeg -h filter="

abbr ff_help_protocol "ffmpeg -h protocol="

#
# ffp = ffprobe
abbr ffp ffprobe
abbr ffph "ffprobe -h full"
#
# -show_***
# I prefer to hide the default log output (i.e. streams info) to avoid confusion about what -show_xxx is displaying
set _show_prefix 'ffprobe -loglevel warning '
abbr --set-cursor ffpshow "$_show_prefix -show_%"
# -show_log
# -show_data (Show packets data)
# -show_data_hash (Show packets data hash)
# -show_entries
# -show_private_data
# -show_error (Show probing error)
# -show_programs
# -show_format_entry
#   (Show a particular entry from the format/container info)
#

# * volumedetect
function _create_abbr_ff_help_filter --argument-names type filter
    set abbr_name "ff_help_filter_"$type"_$filter"
    set url "https://ffmpeg.org/ffmpeg-filters.html#$filter"
    abbr --add $abbr_name "ffmpeg --help filter=$filter && open $url"
end

# audio filters
_create_abbr_ff_help_filter audio acompressor
_create_abbr_ff_help_filter audio aecho
_create_abbr_ff_help_filter audio afftdn
_create_abbr_ff_help_filter audio aformat
_create_abbr_ff_help_filter audio aresample
_create_abbr_ff_help_filter audio astats
_create_abbr_ff_help_filter audio loudnorm
_create_abbr_ff_help_filter audio silencedetect
_create_abbr_ff_help_filter audio volumedetect

# video filters
_create_abbr_ff_help_filter video crop
_create_abbr_ff_help_filter video drawtext
_create_abbr_ff_help_filter video fps
_create_abbr_ff_help_filter video hflip
_create_abbr_ff_help_filter video overlay
_create_abbr_ff_help_filter video scale
_create_abbr_ff_help_filter video transpose
_create_abbr_ff_help_filter video vflip
_create_abbr_ff_help_filter video whisper

abbr ff_volumedetect --set-cursor --function _ff_volumedetect
function _ff_volumedetect
    set -l input (_find_first_video_file_any_type; or echo "%")
    echo -n "ffmpeg -i $input -filter:a volumedetect -f null /dev/null 2>&1 | grep Parsed"
end

abbr --add ff_silencedetect --set-cursor --function _ff_silencedetect
function _ff_silencedetect
    set input (_find_first_video_file_any_type; or echo "%")
    echo -n "ffmpeg -i $input -af silencedetect=noise=d=0.1:-30dB -f null -"
end

# * astats
abbr --add ff_astats --set-cursor --function _ff_astats
function _ff_astats
    set options ""
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end
#
abbr --add ff_astats_per_frame --set-cursor --function _ff_astats_per_frame
function _ff_astats_per_frame
    set options "metadata=1:reset=1,ametadata=print:file=astats-per-frame.txt"
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end
#
abbr --add ff_astats_overall --set-cursor --function _ff_astats_overall
function _ff_astats_overall
    # FTR =1 results in ONLY per OVERALL stats
    # ffmpeg -i record-silence-w-streamdeck-button-press-start-end.mkv -af astats=measure_overall=1 -f null -
    set options "measure_overall=1"
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end
#
abbr --add ff_astats_perchannel --set-cursor --function _ff_astats_perchannel
function _ff_astats_perchannel
    # FTR =1 results in ONLY per channel showing (one set per channel in video/audio file)
    set options "measure_perchannel=1"
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end

# https://ffmpeg.org/ffmpeg-filters.html#whisper
# TODO try out VAD + openai whisper filter!!!
#  two models in one tool! slice on activity, then transcribe it
# TODO abbr ff_vad_plus_whisper "ffmpeg -i % -filter_complex \"[0:a]vad,whisper\""
# TODO => must build w/ ./configure --enable-whisper
#  and then download a ggml model for whisper
#  and find a ggml VAD model ... ggml-silero-v5.1.2
# TODO what else does ffmpeg have for VAD...
#    i.e. whisper.cpp/models/ggml-silero-v5.1.2.bin
#    git clone ggml-org/whisper.cpp
#    uv venv? && uv pip install -r models/requirements-coreml.txt + models/requirements-openvino.txt
#    * models/download-vad-model.sh silero-v5.1.2
#    * models/download-ggml-model.sh tiny

# TODO idea... how about pull last video argument from command history (limit to recent history?) => fallback one video in current dir only => else blank?
abbr --add ffpshow_chapters --set-cursor --function _ffpshow_chapters
function _ffprobe_expand_cmd --argument-names template
    set -l video (_find_first_video_file_any_type)
    string replace "%" "$video%" $template
end

function _ffpshow_chapters
    _ffprobe_expand_cmd "$_show_prefix -show_chapters % | bat -l ini"
end

function _ffpshow_packets_video
    _ffprobe_expand_cmd "$_show_prefix -select_streams v:0 -show_packets % | bat -l ini"
end
abbr --add ffpshow_packets_video --set-cursor --function _ffpshow_packets_video

function _ffpshow_packets_audio
    _ffprobe_expand_cmd "$_show_prefix -select_streams a:0 -show_packets % | bat -l ini"
end
abbr --add ffpshow_packets_audio --set-cursor --function _ffpshow_packets_audio

function _ffpshow_streams
    _ffprobe_expand_cmd "$_show_prefix -show_streams % | bat -l ini"
end
abbr --add ffpshow_streams --set-cursor --function _ffpshow_streams

function _ffpshow_stream_groups
    _ffprobe_expand_cmd "$_show_prefix -show_stream_groups % | bat -l ini"
end
abbr --add ffpshow_stream_groups --set-cursor --function _ffpshow_stream_groups

function _ffpshow_frames_video
    _ffprobe_expand_cmd "$_show_prefix -select_streams v:0 -show_frames % | bat -l ini"
end
abbr --add ffpshow_frames_video --set-cursor --function _ffpshow_frames_video

function _ffpshow_frames_audio
    _ffprobe_expand_cmd "$_show_prefix -select_streams a:0 -show_frames % | bat -l ini"
end
abbr --add ffpshow_frames_audio --set-cursor --function _ffpshow_frames_audio

function _ffpshow_format
    _ffprobe_expand_cmd "$_show_prefix -show_format % | bat -l ini"
end
abbr --add ffpshow_format --set-cursor --function _ffpshow_format

# count read frames/packets vs recorded count (must show streams to see counts that are added as nb_read_xxx)
function _ffpcount_frames
    _ffprobe_expand_cmd "$_show_prefix -count_frames -show_streams % | bat -l ini"
end
abbr --add ffpcount_frames --set-cursor --function _ffpcount_frames

function _ffpcount_packets
    _ffprobe_expand_cmd "$_show_prefix -count_packets -show_streams % | bat -l ini"
end
abbr --add ffpcount_packets --set-cursor --function _ffpcount_packets

function _ffpcount_both
    _ffprobe_expand_cmd "$_show_prefix -count_packets -count_frames -show_streams % | bat -l ini"
end
abbr --add ffpcount_both --set-cursor --function _ffpcount_both

#
# not video specific
# -show_pixel_formats (Show pixel format descriptions)
abbr ffpshow_pixel_formats "$_show_prefix -show_pixel_formats"
abbr ffpshow_version "$_show_prefix -show_program_version"

# * ffpl = ffplay
abbr ffpl ffplay
abbr ffplh "ffplay -h full"

### *** sips command
abbr sipsg "sips -g all"
# mostly will use sRGB Profile, if not then at least I can modify this command for a different profile:
# -o file/dir => instead of in-place update, write the modified image file to a new file/dir
abbr sipsm "sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -o new_image_file "
abbr sipsx "sips -x profile_extracted_here" # extract a profile from an image
# embed = insert a profile w/o modifying the raw pixels
# match = modify the raw pixels to match the profile, and embed that profile too
abbr sipsf "sips --formats" # list supported formats
