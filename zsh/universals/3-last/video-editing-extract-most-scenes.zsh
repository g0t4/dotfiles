#!/bin/bash

# TODO - try using scdet instead of my old method and compare results
# scdet # Detect video scene change
# ffmpeg -filters | grep scdet

# USAGE: video_editing_extract_most_scene_change_thumbnails *.mp4
function video_editing_extract_most_scene_change_thumbnails() {

  if [ ${#@} -eq 0 ]; then
    log_error "please pass video files to check, ie: *.mp4"
    log_info  " AND pass optional scene change threshold (default 0.05)"
    return
  fi
  if ! command -v ffmpeg > /dev/null; then
    log_aborting "ffmpeg command not available, install it and try again..."
    return -1
  fi

  # pre-req -> must have ffmpeg compiled with drawtext filter, mbpy has this
  if ! (ffmpeg -filters | grep drawtext > /dev/null); then
    echo "ffmpeg not compiled with drawtext filter, can't generate timecodes on scenes"
    echo "aborting..."
    # TODO - I could turn this feature off I suppose
    return -1
  fi

  local last_arg=${@: -1}
  if [[ $last_arg =~ ^[0-9\.]+$ ]]; then
    # last arg is a numeric so interpret that as scene change threshold:
    local scene_threshold=$last_arg
    # files are all but last arg:
    local _files=(${@:1:$#-1}) # use () to keep type as array
  else
    # no threshold provided, use default:
    local scene_threshold="0.05"
    local _files=(${@}) # use () to keep type as array (otherwise it would be a scalar and for loop below would not work)
  fi

  log_info "scene change threshold: ${scene_threshold}"
  log_info "files to check: ${_files}"

  # Known Potential Misses
  # (no guarantee all scene changes detected)
  # - adding a bullet
  # - transitioning from title slide => slide w/ first bullet
  # (not sure how scdet filter would compare)

  local _timestamp=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
  local _scenes_dir="scenes_${scene_threshold}_${_timestamp}"
  # if for some odd reason, dir exists, trash it
  if [ -e "${_scenes_dir}" ]; then
    log_warn "unexpected error - tmp dir already exists: '${_scenes_dir}' - rerun to try again (at later second?)... aborting..."
    return
  fi
  log_info "writing scenes to ${_scenes_dir}"
  mkdir "${_scenes_dir}"

  # TODO - yes ok nullglob check like in tldr_any that I figured out - it works
  for clip in ${_files}; do
    log_info "processing ${clip}"

    # NOTE: prefix with echo to test changes - you won't see double quote escaping even though it is there
    ffmpeg \
      -i "$clip" \
      -vf "select='if(eq(n,0),1,gte(scene,${scene_threshold}))',drawtext=text='%{pts\:hms}':fontsize=60:x=w-tw-10:y=h-th-10" \
      -vsync vfr \
      "${_scenes_dir}/${clip}-%d.png"
    # TODO - any updates to drawtext to allow timecode to go onto filename?
  done

  # NOTES:
  # eq(n,0) grabs the first frame b/c it won't be treated as a scene change
  # gte(scene,0.2) grabs all frames with a scene change greater than 20% probability
    # seems like 5% is needed on terminal demos just to get about any scene detection - maybe my transitions are too smooth to notice beyond change window from terminal to browser or back and that might be it
      # tried 1% - works much better!
  # drawtext adds timecode of frame in original video
  # vsync vfr changes to variable frame rate otherwise original frame rate is kept with the original pts's so basically selected frames just replace all frames after them and we export hundreds of unneeded copies of these scene change frames
  # output file with original clip at start and then incrementing counter - I wish this could be timecode (pts) so I didn't have to draw that on image but oh well it can't be at this time

}
