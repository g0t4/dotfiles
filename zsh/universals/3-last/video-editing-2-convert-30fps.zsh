# USAGE: video_editing_2_convert_30fps *.mp4
function video_editing_2_convert_30fps() {

  # PRN parallelize this? https://stackoverflow.com/questions/61948652/zsh-and-parallel-how-to-use-functions-it-says-command-not-found

  for clip_file in $@; do

    clip=${clip_file:t:r}
    echo "clip title: '$clip'"
    abs_parent_dir="${clip_file:h}" # use :a:h for abs path, or :h:a
    echo "  in ${abs_parent_dir}"

    dest_dir="${abs_parent_dir}/ready-to-submit"
    mkdir -p "$dest_dir"
    dest_file="${dest_dir}/${clip}.30fps.mp4" # *** I use 30fps to double check what I uploaded is right
    echo "  saving to ${dest_file}"

    original_dir="${abs_parent_dir}/originals-from-som"
    mkdir -p "$original_dir"

    # copy the audio stream (don't re-encode it - otherwise it was dropping bitrate by 30% in my initial conversions)
    ffmpeg -i "${clip_file}" \
      -c:a copy \
      -r 30 \
      "${dest_file}"

    if [ $? -ne 0 ]; then
      log_error "ERROR: failed to convert $source_file"
      log_error "   ffmpeg had non-zero exit code: $?"
      log_warn "   ABORTING further conversions, fix and then resume"
      return
    fi

    if [ ! -f "$dest_file" ]; then
      log_error "ERROR: ffmpeg did not create the expected output file: $dest_file"
      log_warn "   ABORTING further conversions, fix and then resume"
      return
    fi

    # storing the original shasum in metadata so I can tie back to the original file if needed
    local _shasum_original=$(shasum -a 256 "$clip_file" | cut -c -8)
    exiftool -overwrite_original \
      -Comment="original_shasum=${_shasum_original}" \
      "$dest_file"
    # FYI must modify tag before sha256sum is calculated (otherwise it will differ and would throw me off in future) IIUC about metadata anyways

    #   FYI I can re-run ffmpeg conversion (assuming same parameters) then it will produce same output so I could figure it out in a pinch that way too
    local _shasum=$(shasum -a 256 "$dest_file" | cut -c -8)
    # use spaces around shasum in name - easier to select with textsniper and double click in iTerm/browser
    local _dest_file_with_shasum="${dest_file:r} ${_shasum} .mp4" # wow copilot suggested this, and its good!
    echo "  saving to ${_dest_file_with_shasum}"
    mv "$dest_file" \
      "$_dest_file_with_shasum"

    # move original to clobber free name (appended shasum)
    local _original_file_with_shasum="$original_dir/${clip_file:r} ${_shasum_original} .mp4"
    echo "  moving original to ${_original_file_with_shasum}"
    mv "$clip_file" \
      "$_original_file_with_shasum"

  done
}
