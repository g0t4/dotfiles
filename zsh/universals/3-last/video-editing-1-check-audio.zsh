# USAGE: video_editing_1_check_audio *.mp4
function video_editing_1_check_audio() {

  if [ "${#@}" -eq 0 ]; then
    echo "no files specified, using *.mp4 in current dir"
    search_in=(*.mp4)
  else
    search_in=("${@[@]}")
  fi

  for clip in ${search_in}; do

    log_blue "\n## ${clip:t} "

    # TODO review that I changed everything correctly from 0.5-1s => 0.8s-1.3s
    # CASES
    # - end silence < 0.8 seconds
    # - end silence > 1.3 second
    # - no silence at end (IIUC this means < 0.8 since that is my threshold for silencedetect duration (d=0.8))
    # START SILENCE CHECK
    # read in first 2 seconds else it will always find end at 1.3 second or less :)
    # FYI -t is duration to read at start, -to is position (so if timecodes are off then it doesn't take first 2 seconds)... IIUC from docs https://ffmpeg.org/ffmpeg-all.html#Main-options
    start_silence_detects=$( ffmpeg -hide_banner -t 2 -i "$clip" \
      -af "silencedetect=d=0.8" \
      -f null /dev/null 2>&1 )
    start_silence_ends=$( echo $start_silence_detects  | grep -o "silence_end:.*" | head -n 1 )
    # ffmpeg output goes to stderr so redir to stdout (2>&1) and then grep for silence_end
    # FYI end paren must have space between it and -f2 )... NOT f2) or it will fail
    _ends_at=$( echo $start_silence_ends | cut -d' ' -f2 )
    _duration=$( echo $start_silence_ends | cut -d' ' -f5 )
    if [ -z "$start_silence_ends" ]; then
      # no silence_end records => less than 0.8 seconds
      log_error "@start no silence > 0.8 seconds detected"
    else
      # silence detect records => greater than 0.8 seconds, so now just check for > 1.3 second
      # NOTE: use end at (silence_end) b/c that will catch duration > 1.3 AND/OR if first silence isn't at start of file
      if (( $_ends_at > 1.3 )); then
        log_error "@start silence greater than 1.3 second"
      fi
      echo "[@start] ${start_silence_ends}"
    fi

    # END SILENCE CHECK
    # look at silence in last 2 seconds... should enough to assume that duration as a check is all I need
    end_silence_detects=$( ffmpeg -hide_banner -sseof -2 -i "$clip" \
      -af "silencedetect=d=0.8" \
      -f null /dev/null 2>&1 )
    end_silence_duration=$( echo $end_silence_detects | grep -o "silence_end:.*" | tail -n 1 )
    _end_ends_at=$( echo $end_silence_duration | cut -d' ' -f2 )
    _end_duration=$( echo $end_silence_duration | cut -d' ' -f5 )
    if [ -z "$end_silence_duration" ]; then
      # no silence_end records => less than 0.8 seconds
      log_error "@end no silence > 0.8 seconds detected"
    else
      if (( $_end_duration > 1.3 )); then
        log_error "@end silence greater than 1.3 seconds"
      fi
      # PRN 1.95 might not always work depending on the video but I think it will, maybe drop to 1.92 if false positive
      if (( $_end_ends_at < 1.95 )); then
        log_error "@end silence appears to stop before end of clip, is there noise at the end?"
      fi
      echo "[@end] ${end_silence_duration}"
    fi
    # ametadata https://ffmpeg.org/ffmpeg-all.html#metadata_002c-ametadata
    # ffmpeg -hide_banner -i "$clip" \
    #   -af "volumedetect,ametadata=print:key=lavfi.r128.I, file=openvino.log:overwrite=true" -f null /dev/null

      #  -af "volumedetect,ametadata=print:key=lavfi.r128.I, file=openvino.log:overwrite=true" -f null /dev/null


    ####### VOLUME DETECT ON ENTIRE CLIP
    # FYI add -t 10 to take first 10 seconds only, add before -i option
    _parsed=$(ffmpeg -hide_banner -i "$clip" \
      -af volumedetect -f null /dev/null 2>&1 | grep Parsed)
    _max_volume=$(echo $_parsed | grep -o "max_volume:.*" | cut -d' ' -f2)
    _mean_volume=$(echo $_parsed | grep -o "mean_volume:.*" | cut -d' ' -f2)
    _n_samples=$(echo $_parsed | grep -o "n_samples:.*" | cut -d' ' -f2)
    echo "volume: MEAN: $_mean_volume, MAX: $_max_volume, n_samples: $_n_samples"
    _histogram=$(echo $_parsed | grep -o "histogram.*")
    # IIUC no reason why max_volume wouldn't be <= max of histogram too?
    # max is expressed as a negative number so -3.0 is 3dB ... so if max is > -3.0 then it is too loud (at least)
    # most clips should be 4/5/6 as topmost level (a few samples at 3dB is fine too), > 10@3dB is maybe an indicator that smth is too loud?
    if (( $_max_volume > -3.0 )); then
      log_error "max volume < 3dB"
    fi
    echo $_histogram # for now print for all clips (red of errors stands out)

    echo
    echo

    # todo ebur128 loudness filter!
    #  learn: https://tech.ebu.ch/loudness
    # cool way to understand this: video output that shows levels!
    #   ffplay -f lavfi -i "amovie=m02c30.mp4,ebur128=video=1:meter=18 [out0][out1]"

  done

}
