### *** exiftool

ealias exiftool="grc exiftool"
# TODO if I add secondary expansions then need to inline this in them or find a way to recursively expand aliases (does fish do that? with abbr?)

### *** ffmpeg et al
alias ffmpeg="ffmpeg -hide_banner"
alias ffprobe="ffprobe -hide_banner"
alias ffplay="ffplay -hide_banner"
# FYI some of these are reminders when I revisit ffmpeg (i.e. to know what to get help for)
ealias ff="ffmpeg"
ealias ffm="ffmpeg"
ealias ffh="ffmpeg -h full" # full help is far superior to ffmpeg-all which doesn't really show device specific options/devices/filters/formats/etc
ealias ffhe="ffmpeg -h encoder="
ealias ffhd="ffmpeg -h decoder="
ealias ffhmx="ffmpeg -h muxer="
ealias ffhdx="ffmpeg -h demuxer="
ealias ffhf="ffmpeg -h filter="
ealias ffhb="ffmpeg -h bsf="
ealias ffhp="ffmpeg -h protocol="
#
# ffp = ffprobe
ealias ffp="ffprobe"
ealias ffph="ffprobe -h full"
# ffpl = ffplay
ealias ffpl="ffplay"
ealias ffplh="ffplay -h full"

### *** sips command
ealias sipsg="sips -g all"
# mostly will use sRGB Profile, if not then at least I can modify this command for a different profile:
# -o file/dir => instead of in-place update, write the modified image file to a new file/dir
ealias sipsm="sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -o new_image_file "
ealias sipsx="sips -x profile_extracted_here" # extract a profile from an image
# embed = insert a profile w/o modifying the raw pixels
# match = modify the raw pixels to match the profile, and embed that profile too
ealias sipsf="sips --formats" # list supported formats
