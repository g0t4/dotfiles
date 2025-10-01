### *** exiftool

abbr exiftool "grc exiftool"
# TODO if I add secondary expansions then need to inline this in them or find a way to recursively expand aliases (does fish do that? with abbr?)
abbr exifc "grc exiftool -common -duration -AudioFormat -CompressorName" # limit to common metadata that I look for
abbr exifs "grc exiftool -s" # show tag names instead of descriptions

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
abbr ff "ffmpeg"
abbr ffm "ffmpeg"
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
abbr ffp "ffprobe"
abbr ffph "ffprobe -h full"
# ffpl = ffplay
abbr ffpl "ffplay"
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
