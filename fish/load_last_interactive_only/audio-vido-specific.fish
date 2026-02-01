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
abbr ffh "ffmpeg -h full" # full help is far superior to ffmpeg-all which doesn't really show device specific options/devices/filters/formats/etc
abbr ffhe "ffmpeg -h encoder="
abbr ffhd "ffmpeg -h decoder="
abbr ffhmx "ffmpeg -h muxer="
abbr ffhdx "ffmpeg -h demuxer="
abbr ffhf "ffmpeg -h filter="
abbr ffhb "ffmpeg -h bsf="
abbr ffhp "ffmpeg -h protocol="
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
# TODO idea... how about pull last video argument from command history (limit to recent history?) => fallback one video in current dir only => else blank?
abbr --add ffpshow_chapters --set-cursor --function _ffpshow_chapters
function _ffprobe_expand_cmd -a template
    set -l video (_find_first_video_file_any_type; or echo _)
    printf '%s' (string replace "%" "$video" $template)
end

function _ffpshow_chapters
    echo -n (_ffprobe_expand_cmd "$_show_prefix -show_chapters % | bat -l ini")
end


abbr --set-cursor ffpshow_packets_video "$_show_prefix -select_streams v:0 -show_packets % | bat -l ini"
abbr --set-cursor ffpshow_packets_audio "$_show_prefix -select_streams a:0 -show_packets % | bat -l ini"
abbr --set-cursor ffpshow_streams "$_show_prefix -show_streams % | bat -l ini"
abbr --set-cursor ffpshow_stream_groups "$_show_prefix -show_stream_groups % | bat -l ini"
abbr --set-cursor ffpshow_frames_video "$_show_prefix -select_streams v:0 -show_frames % | bat -l ini"
abbr --set-cursor ffpshow_frames_audio "$_show_prefix -select_streams a:0 -show_frames % | bat -l ini"
abbr --set-cursor ffpshow_format "$_show_prefix -show_format % | bat -l ini" # format/container info
#
# count read frames/packets vs recorded count (must show streams to see counts that are added as nb_read_xxx
abbr --set-cursor ffpcount_frames "$_show_prefix -count_frames -show_streams % | bat -l ini"
abbr --set-cursor ffpcount_packets "$_show_prefix -count_packets -show_streams % | bat -l ini"
abbr --set-cursor ffpcount_both "$_show_prefix -count_packets -count_frames -show_streams % | bat -l ini"
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
