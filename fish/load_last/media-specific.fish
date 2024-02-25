### *** exiftool

eabbr exiftool "grc exiftool"
# TODO if I add secondary expansions then need to inline this in them or find a way to recursively expand aliases (does fish do that? with abbr?)
eabbr exifc "grc exiftool -common -duration -AudioFormat -CompressorName" # limit to common metadata that I look for
eabbr exifs "grc exiftool -s" # show tag names instead of descriptions

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
eabbr ff "ffmpeg"
eabbr ffm "ffmpeg"
eabbr ffh "ffmpeg -h full" # full help is far superior to ffmpeg-all which doesn't really show device specific options/devices/filters/formats/etc
eabbr ffhe "ffmpeg -h encoder="
eabbr ffhd "ffmpeg -h decoder="
eabbr ffhmx "ffmpeg -h muxer="
eabbr ffhdx "ffmpeg -h demuxer="
eabbr ffhf "ffmpeg -h filter="
eabbr ffhb "ffmpeg -h bsf="
eabbr ffhp "ffmpeg -h protocol="
#
# ffp = ffprobe
eabbr ffp "ffprobe"
eabbr ffph "ffprobe -h full"
# ffpl = ffplay
eabbr ffpl "ffplay"
eabbr ffplh "ffplay -h full"

### *** sips command
eabbr sipsg "sips -g all"
# mostly will use sRGB Profile, if not then at least I can modify this command for a different profile:
# -o file/dir => instead of in-place update, write the modified image file to a new file/dir
eabbr sipsm "sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -o new_image_file "
eabbr sipsx "sips -x profile_extracted_here" # extract a profile from an image
# embed = insert a profile w/o modifying the raw pixels
# match = modify the raw pixels to match the profile, and embed that profile too
eabbr sipsf "sips --formats" # list supported formats
