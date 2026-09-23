# *** elgato profile sync ***
# NOTES
# - device names are stored in /Users/wesdemos/Library/Preferences/com.elgato.StreamDeck.plist
#   - just manually sync device names, mostly so I can make my streamdeck buttons to switch device
#   - otherwise doesn't matter if they differ given everything is a UUID (blessing and curse)
# - each profile is linked to device by UUID
#   bat **/manifest.json | jq .Device.UUID | sort | uniq -c  # count # per device UUID
#   bat **/manifest.json | jq .Name # show profile names
#

function elgato_kill_other_account_streamdeck
    # kill them before you change settings in current account's streamdeck, otherwise on quit the other one may overwrite new settings
    set other_user wes

    if test $USER = wes
        set other_user wesdemos
    else
        set other_user wes
    end

    sudo pkill -U $other_user -ilf "stream deck"
    sudo pkill -U $other_user -ilf streamdeck
    # just open other account's streamdeck next time you switch to it
end

# *** images

function show_pixel_color --argument-names image left top
    set hex_color $(magick $image -format "%[hex:p{$left,$top}]" info: | head -c6)
    echo "HEX: $hex_color"
    set srgba_color $(magick $image -format "%[pixel:p{$left,$top}]" info:)
    echo "SRGBA: $srgba_color"
    magick -size 200x100 xc:"#$hex_color" png:- | imgcat
end

function show_pixel_column --argument-names image left top count
    set y $top
    if test -z $count
        set count (magick $image -format "%[h]" info:)
        set count (math "$count - $top")
    end
    for i in (seq $count)
        echo "$y"
        show_pixel_color $image $left $y
        set y (math "$y + 1")
    end
end

# *** video editing wrappers ***

function quote_paths
    for path in $argv
        echo "'$path'"
    end
end

function video_editing_total_duration
    # wow I used my ask-openai CLI helper to generate this and it did and it works well (asked for first to get durations, then said split hours:mins:secs and sheesh it did it right using one lone command line with semicolon separators, I just split it out here... bravo this is not straightforward to do
    set totalSeconds 0
    for file in $argv
        set duration (ffmpeg -i $file 2>&1 | rg_grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        set -l h (echo $duration | cut -d ':' -f1)
        set -l m (echo $duration | cut -d ':' -f2)
        set -l s (echo $duration | cut -d ':' -f3)
        set totalSeconds (math "$totalSeconds + ($h * 3600) + ($m * 60) + $s")
    end
    set -l hours (math "floor($totalSeconds / 3600)")
    set -l minutes (math "floor(($totalSeconds % 3600) / 60)")
    set -l seconds (math "$totalSeconds % 60")
    echo $hours:$minutes:$seconds

end
# *** thumbnails
abbr --add _150 --function abbr_thumbnail_check
function abbr_thumbnail_check
    set suffix "150px.png"
    set first_image (ls *.png | rg_grep --invert-match $suffix | head -1)
    set input_file (quote_paths "$first_image")
    set output_file (quote_paths "$(path basename --no-extension "$first_image").$suffix")
    echo "magick $input_file -resize 150 $output_file"
    echo "imgcat $output_file"
    # TODO apply quote_paths to more parts of similar abbrs
end

# *** #1 check audio ***
abbr --add _1 --function abbr_check
function abbr_check
    echo -n "video_editing_1_check_audio "
    abbr_videos_glob_for_current_dir
end
function abbr_videos_glob_for_current_dir
    # quite often I want to target all video files in current dir, so find those by different extensions and expand appropriately to match most use cases (priority order)
    if count *.mp4 >/dev/null
        echo -n "*.mp4"
    else if count *.m4v >/dev/null
        echo -n "*.m4v"
    else if count *.mkv >/dev/null
        echo -n "*.mkv"
    else if count *.mov >/dev/null
        echo -n "*.mov"
    end
    # default case don't add glob to match all video files
end
# FYI `veaud<TAB>` works in fish shell to complete this func:
function video_editing_1_check_audio
    # only arg would be file paths (i.e. from glob like *.mp4), btw dont need to pass any paths and it will do all *.mp4 in current dir
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_1_check_audio $paths"
end

# *** #2 convert 30fps ***
abbr --add _2 --function abbr_30fps
function abbr_30fps
    echo -n "video_editing_2_convert_30fps "
    abbr_videos_glob_for_current_dir
end
# FYI `veconv<TAB>` works in fish shell to complete this func:
function video_editing_2_convert_30fps
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_2_convert_30fps $paths"
end

function video_editing_extract_most_scene_change_thumbnails
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_extract_most_scene_change_thumbnails $paths"
end

abbr --add _mp4 --function abbr_mp4
function abbr_mp4
    # for now all mkv => mp4 helper func
    if test (ls *.mkv | count) -gt 0
        for mkv in *.mkv
            set output_file (path change-extension mp4 "$mkv")
            if test -f "$output_file"
                continue
            end
            echo ffmpeg -i "'$mkv'" -c copy "'$output_file'"
        end
    end
end

function _video_editing_ffmpeg_file_list
    for p in $argv
        # use realpath to get absolute path, that way no issues w/ relative paths
        echo "file '$(realpath $p)'"
    end
end

function _get_first_file_dir
    realpath $(dirname $argv[1])
end

function _get_output_file_based_on_first_file
    # ! assumes -c copy so really only works on mkv/mp4 and similar types
    set output_name $argv[1] # i.e. combined.mp4 (first arg is output file name w/o path)
    set paths $argv[2..-1] # i.e. /Users/wes/foo/bar/baz.mp4 /Users/wes/foo/bar/baz.mp4

    set path (_get_first_file_dir $paths[1])
    set output_file "$path/$output_name"
    echo $output_file
end

function _ffmpeg_concat
    set combined_file (_get_output_file_based_on_first_file combined.mp4 $argv)

    ffmpeg -f concat -safe 0 \
        -i (_video_editing_ffmpeg_file_list $argv | psub) \
        -c copy $combined_file
end

function _find_first_video_file_for_extension
    set ext $argv[1]
    set -f paths (fd --unrestricted --max-depth 1 --type f --extension $ext)
    if test (count $paths) -gt 0
        echo $paths[1]
        return
    end
    return 1
end

function _find_first_video_file_any_type
    # todo other types
    for ext in mp4 mkv mov
        set path (_find_first_video_file_for_extension $ext)
        if test "$path" != ""
            echo $path
            return
        end
    end
    return 1
end

# * timing and other checks on streams in videos
abbr _3 video_editing_3_dropped_frames
function video_editing_3_dropped_frames
    set _python3 "$WES_DOTFILES/.venv/bin/python3"
    env PYTHONPATH="$WES_DOTFILES/fish/load_last_interactive_only/pythons/av" $_python3 -m dropped_frames $argv
end
complete -c video_editing_3_dropped_frames -a --verbose

abbr --add ffp --function _ffp
function _ffp
    echo -n "ffprobe -i "
    _find_first_video_file_any_type; or echo _
end

abbr --add ffi_range --set-cursor --function _ffi_trim
abbr --add ffi_trim --set-cursor --function _ffi_trim
function _ffi_trim
    set input (_find_first_video_file_any_type; or echo _)
    set output (path change-extension ".trimmed.mp4" $input)
    # echo -n "ffmpeg -i combined.shifted100ms.mp4 -ss 00:08:52 -to 00:09:22 -c:v copy -c:a copy trimmed-5m10s_to_5m40s.mp4"
    set duration (ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $input)

    echo -n "ffmpeg -i $input -ss 00:00 -to $duration"%" $output"
end

function _ffi_pass_middle_to_new_out
    # w/e is passed is inlined in the middle of the command
    set middle $argv
    set input (_find_first_video_file_any_type; or echo _)
    set output (path change-extension ".out.mp4" $input)
    echo -n "ffmpeg -i $input $middle $output"
end

abbr --add ffi --set-cursor --function _ffi_copy
abbr --add ffi_copy --set-cursor --function _ffi_copy
function _ffi_copy
    # careful w/ copy, it results in keyframe issues when trimming
    #  IIRC only want to use this when changing container... NOT when changing video
    _ffi_pass_middle_to_new_out "% -c copy"
end

abbr --add ffi_af --set-cursor --function _ffi_af
function _ffi_af
    _ffi_pass_middle_to_new_out "-af '%'"
end

abbr --add ffi_vf --set-cursor --function _ffi_vf
function _ffi_vf
    _ffi_pass_middle_to_new_out "-vf '%'"
end

# IDEAS (make reusable?)... maybe just have a lookup of these in a file somewhere and grep it?
#
# * trim, slow down and label:
# ffmpeg -ss 00:00:14.5 -to 00:00:14.9 -i approve-what-dialog-plugin-mixpre6.mov -an \
#   -filter_complex "[0:v]setpts=20.0*PTS,drawtext=text='20x slow down':fontcolor=white:fontsize=200:x=1500:y=2000:box=1:boxcolor=black@0.5[v]" \
#   -map "[v]" output.mp4
#

abbr --add _aio --function abbr_aio
function abbr_aio
    echo -n "video_editing_aio "
    abbr_videos_glob_for_current_dir
end

abbr shift_only 'for i in *.{mkv,mov}; video_editing_just_shift_to_mp4_one_video $i; end'
function video_editing_just_shift_to_mp4_one_video
    # TODO merge with stage_1 below which does the same thing
    # converts to mp4 + shifts by 100ms
    set video_file (realpath $argv[1])
    set output_file (path change-extension ".shifted100ms.mp4" "$video_file")
    if test -f "$output_file"
        echo "Skipping...file already exists: $output_file"
    else
        ffmpeg -i "$video_file" -itsoffset 0.1 -i "$video_file" -map 0:v -map 1:a -c:v copy -c:a aac "$output_file"
    end
end

function path_stem --argument-names path --description "return path w/o extension, i.e. foo.mp4 => foo"
    # path_stem "foo.mp4" => "foo"
    path change-extension '' $path # (when change to empty, strips dot too)
end

function path_prefix_extension --argument-names prefix path --description "like change-extension except it prefixes instead of replace"
    # path_prefix_extension foo test.mp4    =>    test.foo.mp4
    set file_extension (path extension $path) # foo.mp4 => ".mp4" (dot included)
    set stem (path change-extension '' $path) # foo.mp4 => "foo" (when change to empty, strips dot too)
    echo $stem.$prefix$file_extension # foo.mp4 => foo.prefix.mp4
end

function _video_editing_aio_stage1
    # combine + shift audio timing (mic/video sync)

    set combined_file (_get_output_file_based_on_first_file combined.mp4 $argv)

    # based on: ffmpeg -i foo.mp4  -itsoffset 0.1 -i foo.mp4  -map 0:v -map 1:a -c:v copy -c:a aac foo-shifted100ms.mp4
    # PRN add ms param? right now 100 works for my setup OBS+mixpre6v2/mv7+logibrio
    set stage1_shifted_file (path_prefix_extension shifted100ms "$combined_file")
    if not test -f "$stage1_shifted_file"
        _ffmpeg_concat $argv # produces $combined_file

        # TODO change this to re-encode audio stream? to avoid some issues w/ start=NON-ZERO (ffprobe foo.mp4) output
        ffmpeg -i "$combined_file" -itsoffset 0.1 -i "$combined_file" -map 0:v -map 1:a -c:v copy -c:a aac "$stage1_shifted_file"
        trash $combined_file # be safe with rm, if it was wrong file I wanna have it be recoverable
    end
    echo $stage1_shifted_file
end

function _video_editing_aio_thru_stage2
    set stage1_shifted_file (_video_editing_aio_stage1 $argv)

    # * both_fixed (start time truncation + CFR constant frame rate) for new silence detect tool
    set stage2_fixed_file (path change-extension .cfr_and_start.mp4 "$stage1_shifted_file")
    echo $stage2_fixed_file
    if test -f "$stage2_fixed_file"
        return
    end

    ffmpeg -i "$stage1_shifted_file" \
        # -ss 0.1 # truncate first 100ms to fix timing mismatch from OBS
        -ss 0.1 \
        -map 0:v:0 -map 0:a:0 \
        -vf "fps=30" \
        -af "aresample=async=1" \
        # CFR will fix any gaps in audio samples (or video frames)
        -fps_mode cfr \
        -r 30 \
        -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.2 \
        -c:a aac -ar 48000 -ac 1 \
        "$stage2_fixed_file"
end

function video_editing_aio
    set stage2_fixed_file $(_video_editing_aio_thru_stage2 $argv)
    video_editing_gen_fcpxml "$stage2_fixed_file"
end

function video_editing_gen_fcpxml
    set -l base "$HOME/repos/github/g0t4/auto-edit-suggests"
    set python3 "$base/.venv/bin/python3"
    env PYTHONPATH="$base" $python3 -m generate_fcpxml_notebook $argv
end

abbr --add _Xdb --regex '\d+db' --function abbr_db
function abbr_db
    set boost $argv[1] # i.e. 7db (do not need to have dB captial B... db is fine)

    # if only one video in current dir, select it
    # exclude previous boosted vides i.e. .7dB.m4v
    set video_files (ls *.{mp4,m4v,mov} | rg_grep --invert-match "dB\.[a-z0-9]{3}\$")
    if test (count $video_files) -eq 1
        set video_file $video_files[1]
    end
    echo "video_editing_boost_audio_dB_by $boost $(string escape $video_file)"
end
#abbr 7db "video_editing_boost_audio_dB_by 7dB"

function video_editing_boost_audio_dB_by
    # usage:    video_editing_boost_audio_dB_by 7dB foo.mp4
    set boost_dB (string replace "db" "dB" $argv[1])
    set input_file (realpath $argv[2])

    set boosted_file (path_prefix_extension $boost_dB "$input_file")
    ffmpeg -i "$input_file" -af "volume=$boost_dB" -c:v copy "$boosted_file"
end

# *** macOS screenshot helpers (for alfred file action => move here)

function _screenshots_trash_secondary_display
    # get rid of any second display screenshots (trash them for now, can always recover them if I really care later)
    for png in "$SCREENCAPS_DIR/"*"(2)"*.png
        # for doesn't fail if wildcard doesn't match anything: https://fishshell.com/docs/current/fish_for_bash_users.html#wildcards-globs
        trash $png
    end
end

function move_screenshots_from_last_x_hours
    set -l hours $argv[1]
    set -l dest_dir $argv[2]
    if test -z $hours
        echo "Usage: move_screenshots_from_last_x_hours <hours> <dest_dir>"
        return 1
    end
    if test -z $dest_dir
        echo "Usage: move_screenshots_from_last_x_hours <hours> <dest_dir>"
        return 1
    end

    # todo modeline to specify python in this embedded string/pseduofile
    echo "
from pathlib import Path
import os
import re
from datetime import datetime, timedelta

hours = $hours
dest_dir = Path(os.path.expanduser('$dest_dir'))
screencaps = Path(os.path.expanduser('$SCREENCAPS_DIR'))

formatted_str = '%Y-%m-%d at %H.%M.%S'
now = datetime.now()
cut_off = now - timedelta(hours=hours)
print('cutoff: ' , cut_off)

# example filename (varies by hostname):
#     hostfoo screencap 2024-09-27 at 00.26.43.png
# must match entire filename (full string contents)
date_time_pattern = r'.*screencap (\d\d\d\d-\d\d-\d\d at \d\d\.\d\d\.\d\d).*.png'

for png in screencaps.glob('*.png'):
    name = png.name
    matches = re.match(date_time_pattern, name)
    if not matches:
        continue
    time_str = matches.group(1)
    parsed_date = datetime.strptime(time_str, formatted_str)
    if cut_off > parsed_date:
        continue
    # png.rename(dest_dir / name)
    new_path = dest_dir / name
    print(f'moving {png} to {new_path}')
    png.rename(new_path)

" | python3

end

if command --query virsh
    # mostly convenience for the times I work intensely on VMs and other infra
    # ONLY the most prevalent commands I feel like suck w/ tab completion alone

    abbr virshl "virsh list"
    abbr virshla "virsh list --all"
    # abbr virshc "virsh console"

    abbr virshd "virsh define"
    abbr virshu "virsh undefine"
    abbr virshdx "virsh dumpxml"

    # leave these for when I spend more time and feel pain specifically, tab complete is actually working well mostly
    # abbr virshs "virsh start"
    # abbr virshdestory "virsh destroy"
    # abbr virshreboot "virsh reboot"
    # virsh vshresume "virsh resume"
    # virsh destroy - missing completions (completes files, needs --no-files and needs to complete domain names like `virsh start`)
    #    others: domstate, domstats, ... find and contribute other fixes (fish shell completions)

    abbr --set-cursor -- vshn 'virsh net-%' # complete the net subcommand, might be cool to hit TAB too automatically... could an abbreviation generate any sort of keyboard input?
    abbr virshnl "virsh net-list"
    # abbr virshndx "virsh net-dumpxml"
    abbr virshndl "virsh net-dhcp-leases" # mostly as reminder if Ctrl+S in virsh abbrs

end

if command --query cargo

    abbr cacl "cargo clean"
    abbr cab "cargo build"
    abbr car "cargo run"
    abbr catest "cargo test"
    abbr cabench "cargo bench" # reminder to investigate

    abbr caa "cargo add"
    abbr carm "cargo remove"
    abbr cau "cargo update"

    abbr canew "cargo new"
    abbr cainit "cargo init"
    abbr cas "cargo search"

end

function find_huge_files
    # find_huge_files +1M
    # find_huge_files +10M

    # FYI good question to ask with ask-openai just to validate helper is working
    # from deepseek-chat
    # find . -type f -size +100M -exec ls -lh {} \; | awk '{ print $9 ": " $5 }'

    set size +100M
    if test (count $argv) -gt 0
        set size $argv[1]
    end
    # BTW ~/.cache is a good dir to look for huge files (test command output)

    # find huge files and sort ascending: (deepseek-chat - V3 currently):
    find . -type f -size $size -exec ls -lh {} \; | awk '{ print $9 ": " $5 }' | sort -k2,2h
end

function zedraw
    # zedraw 1.raw
    # for parsing mitm proxy e[x]ported raw (full req/response) files... and dumping the diff of input_excerpt vs output_excerpt to see the diff
    # FYI if headers change then line offsets will change for the request
    # todo can I just save a flow and extract matching requests and run through this so I can take a stream of predictions and review?
    set raw_file "$argv[1]"
    diff_two_commands "head -8 $raw_file | tail -1 | jq .input_excerpt -r" "tail -1 $raw_file | jq .output_excerpt -r"
end

function zedfull
    # show the request only
    set raw_file "$argv[1]"
    set json (head -8 $raw_file | tail -1 | jq) # not so useful to see the markdown embedded inside json fields so lets remove that

    log_ --blue "## .input_events"
    echo $json | jq -r .input_events
    log_ --blue "## .input_excerpt"
    echo $json | jq -r .input_excerpt
    log_ --blue "## .outline"
    echo $json | jq -r .outline

    set output_json (tail -1 $raw_file | jq)
    log_ --blue "## .output_excerpt"
    echo $output_json | jq -r .output_excerpt
end

abbr common comm # why didn't they just call it co
# FYI -1 = left only, -2 = both, -3 = right only
abbr common_left_only comm -2 -3
abbr common_right_only comm -1 -2
abbr common_both comm -1 -3
abbr intersection comm -1 -3

# * screencapture + tesseract to OCR
function screencapture_ocr
    # tmp dir first
    set tmp_dir (mktemp -d)
    # echo $tmp_dir

    set img_file "$tmp_dir/cap.png"
    # F'in tesseract wants to add .txt to the file name... FUUUU seriously... so just do this here
    set text_file "$tmp_dir/ocr"

    # Let user select area for screenshot
    screencapture -s -x "$img_file"

    # OCR
    tesseract "$img_file" "$text_file" >/dev/null 2>&1

    cat "$text_file.txt" # dump for interactive terminals
    cat "$text_file.txt" | pbcopy # and copy to clipboard

    trash $tmp_dir
end

# *** java abbrs
abbr java19 'export "PATH=$(/usr/libexec/java_home -v 19)/bin:$PATH"'

# *** jcmd
abbr jcmd_screenpal "jcmd \$(screenpal_pid) " # get PID with `jcmd` or `jps` or `ps aux | rg_grep ScreenPal`

# *** mvn
abbr mvnls 'mvn dependenices:list'
abbr mvntree 'mvn dependenices:tree'
abbr mvnc 'mvn compile'
abbr mvnp 'mvn package'
abbr mvnt 'mvn test'

# *** screenpal
abbr spkill "pkill -ilf screenpal"
# abbr spkilltray "pkill -ilf 'screenpal tray'"
abbr spkilltray "echo disable tray app in partner properties file"
abbr splog "cat ~/Library/ScreenPal-v3/app-0.log"
abbr splogrm "rm ~/Library/ScreenPal-v3/app-0.log"
# PRN tray-0.log ... but don't need it right now
function screenpal_pid
    set --local pid (jcmd | rg_grep ScreenPal | head -1 | cut -d' ' -f1)
    echo $pid
end

# *** streamdeck icon helpers

function streamdeck_svg2png_padded_square_only
    # FTR this was desigend initially to work with screenpal icons (svgs) extracted from JARs which are square to start

    if not test -d drop-originals-svgs-here
        echo "CRAP: missing dir 'drop-originals-svgs-here', created it for you, now put your SVGs in it"
        mkdir -p drop-originals-svgs-here
        return 1
    end

    mkdir -p final tmp_pngs

    for image in drop-originals-svgs-here/*.svg
        # * make 96px wide PNG (height is scaled)
        set base (basename $image .svg)
        set new_png "tmp_pngs/$base.png"
        svg2png --width=96 $image $new_png

        # * make 120px PNG with padding around the 96px PNG
        set new_padded "final/$base.padded.png"
        set width 120
        magick "$new_png" -gravity center -background transparent -extent 120x120 "$new_padded"
    end
end

# *** string extensions

function string_indent
    set --local level $argv[1]
    if is_empty $level
        set level 1
    end
    set --local indent (string repeat -n $level '  ')
    while read -l line
        echo "$indent$line"
    end
end
